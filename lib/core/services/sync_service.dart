import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/dead_letter_queue.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_session_repository.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/results/domain/repos/i_results_repository.dart';
import 'package:church_management_system/features/student/domain/repos/i_pastoral_repository.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:workmanager/workmanager.dart';

/// Represents the current state of the sync engine.
class SyncStatus {
  final bool isSyncing;
  final int pendingCount;
  final int totalCount;
  final bool hasError;
  final String? errorMessage;

  /// Non-null when a [SyncEntry] was moved to the dead-letter queue.
  /// The UI must surface a manual-intervention warning in this case.
  final String? dlqEntryId;
  final String? dlqActionType;

  const SyncStatus({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.totalCount = 0,
    this.hasError = false,
    this.errorMessage,
    this.dlqEntryId,
    this.dlqActionType,
  });

  factory SyncStatus.idle() => const SyncStatus();

  factory SyncStatus.processing(int pending, int total) =>
      SyncStatus(isSyncing: true, pendingCount: pending, totalCount: total);

  factory SyncStatus.success() => const SyncStatus();

  factory SyncStatus.error(String message) =>
      SyncStatus(hasError: true, errorMessage: message);

  /// Emitted when an entry has been evicted to the dead-letter queue.
  factory SyncStatus.dlqEviction(String entryId, String actionType) =>
      SyncStatus(dlqEntryId: entryId, dlqActionType: actionType);
}

/// Centralized offline sync engine.
///
/// Manages a FIFO queue of [SyncEntry] items in Hive and attempts to push
/// them to Firestore whenever network connectivity is available.
class SyncService {
  static const String _boxName = 'sync_queue_box';
  static const int _maxRetries = 5;
  static const int _baseBackoffMs = 500;

  final Connectivity _connectivity;
  final IAttendanceRepository _attendanceRepository;
  final IStudentRepository _studentRepository;
  final IResultsRepository _resultsRepository;
  final AttendanceSessionRepository _sessionRepository;
  final IPastoralRepository _pastoralRepository;
  final DeadLetterQueue _dlq;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isProcessing = false;

  final _statusController = StreamController<SyncStatus>.broadcast();

  /// Stream of sync status updates for the UI to listen to.
  Stream<SyncStatus> get statusStream => _statusController.stream;

  SyncService({
    required IAttendanceRepository attendanceRepository,
    required IStudentRepository studentRepository,
    required IResultsRepository resultsRepository,
    required AttendanceSessionRepository sessionRepository,
    required IPastoralRepository pastoralRepository,
    required DeadLetterQueue deadLetterQueue,
    Connectivity? connectivity,
  }) : _attendanceRepository = attendanceRepository,
       _studentRepository = studentRepository,
       _resultsRepository = resultsRepository,
       _sessionRepository = sessionRepository,
       _pastoralRepository = pastoralRepository,
       _dlq = deadLetterQueue,
       _connectivity = connectivity ?? Connectivity();

  /// Initializes the Hive box and starts listening to connectivity changes.
  ///
  /// Call this from the foreground app. For background Workmanager tasks,
  /// call [processQueueOnce] directly after opening Hive — it does NOT
  /// register a connectivity listener.
  Future<void> init() async {
    // Note: Ensure Hive.registerAdapter(SyncEntryAdapter()) is called in main.dart
    await Hive.openBox<SyncEntry>(_boxName);
    await _dlq.init();

    // Listen for network changes to auto-trigger the sync queue
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (!results.contains(ConnectivityResult.none)) {
        unawaited(processQueue());
      }
    });

    // Perform an initial connectivity check
    final results = await _connectivity.checkConnectivity();
    if (!results.contains(ConnectivityResult.none)) {
      unawaited(processQueue());
    }
  }

  /// Lightweight bootstrap used exclusively by the Workmanager background task.
  ///
  /// Opens the Hive boxes, processes the queue exactly once, and returns.
  /// Does NOT register connectivity listeners (unnecessary in a background
  /// isolate that already has a [NetworkType.connected] constraint).
  Future<void> initAndProcessOnce() async {
    await Hive.openBox<SyncEntry>(_boxName);
    await _dlq.init();
    await processQueue();
  }

  /// Adds a new mutation entry to the sync queue.
  Future<void> enqueue(SyncEntry entry) async {
    try {
      final box = Hive.box<SyncEntry>(_boxName);

      // Using put(entry.id) implicitly handles deduplication if the ID is
      // deterministically generated (e.g., 'mark_attendance_user1_session2').
      await box.put(entry.id, entry);

      _statusController.add(SyncStatus.idle()); // Wake up UI if needed

      // Attempt to sync immediately if online
      final results = await _connectivity.checkConnectivity();
      if (!results.contains(ConnectivityResult.none)) {
        unawaited(processQueue());
      } else {
        // Register a one-off background task to run when connectivity returns
        try {
          await Workmanager().registerOneOffTask(
            'sync_offline_queue',
            'offline_sync_task',
            constraints: Constraints(networkType: NetworkType.connected),
            existingWorkPolicy: ExistingWorkPolicy.replace,
          );
        } catch (e) {
          developer.log(
            'Failed to register Workmanager task',
            error: e,
            name: 'SyncService',
          );
        }
      }
    } catch (e, stack) {
      developer.log(
        'Failed to enqueue SyncEntry',
        error: e,
        stackTrace: stack,
        name: 'SyncService',
      );
    }
  }

  /// Processes the queue sequentially (FIFO), grouping consecutive
  /// [MARK_ATTENDANCE] entries that share the same `(teamId, sessionId)` into
  /// a single Firestore [WriteBatch] to minimise round-trips under the Spark
  /// plan limits.
  ///
  /// **Retry & backoff:** Each entry carries a [SyncEntry.retryCount].
  /// On failure the count is incremented and the entry is re-persisted in
  /// Hive. The next invocation will apply an exponential delay:
  ///   `delay = 500ms × 2^(retryCount − 1)` (capped at entry 5 → 8 s).
  /// After 5 failures the entry is evicted to the dead-letter queue and
  /// [SyncStatus.dlqEviction] is broadcast so the UI can warn the user.
  ///
  /// **LWW:** Individual `MARK_ATTENDANCE` entries rely on the per-entry LWW
  /// check inside [IAttendanceRepository.syncOfflineMark]. The batched path
  /// delegates to [IAttendanceRepository.syncBatchedMarks] which performs
  /// the same check server-side via individual transactions per document.
  Future<void> processQueue() async {
    if (_isProcessing) return;

    final box = Hive.box<SyncEntry>(_boxName);
    if (box.isEmpty) return;

    _isProcessing = true;

    // Snapshot length BEFORE we start — used for progress reporting.
    final int totalEntries = box.length;
    int processedEntries = 0;

    _statusController.add(SyncStatus.processing(totalEntries, totalEntries));

    try {
      // FIFO order: sort ascending by creation time.
      final entries = box.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Walk the FIFO list.  Consecutive MARK_ATTENDANCE entries that share
      // the same (teamId, sessionId) are collapsed into a single batch.
      // All other action types are dispatched individually.
      int i = 0;
      while (i < entries.length) {
        // Re-verify network connectivity before every logical unit of work.
        final connectivity = await _connectivity.checkConnectivity();
        if (connectivity.contains(ConnectivityResult.none)) {
          developer.log(
            'Network lost — pausing sync queue at index $i.',
            name: 'SyncService',
          );
          _statusController.add(
            SyncStatus.error('انقطع الاتصال بالإنترنت أثناء المزامنة.'),
          );
          break;
        }

        final entry = entries[i];

        // ── DLQ eviction ────────────────────────────────────────────────────
        if (entry.retryCount >= _maxRetries) {
          developer.log(
            'SyncEntry ${entry.id} exceeded max retries ($_maxRetries). '
            'Evicting to DLQ.',
            name: 'SyncService',
          );
          await box.delete(entry.id);
          await _dlq.add(entry);
          _statusController.add(
            SyncStatus.dlqEviction(entry.id, entry.actionType),
          );
          processedEntries++;
          _statusController.add(
            SyncStatus.processing(
              totalEntries - processedEntries,
              totalEntries,
            ),
          );
          i++;
          continue;
        }

        // ── MARK_ATTENDANCE batching ─────────────────────────────────────────
        // Collect all consecutive MARK_ATTENDANCE entries that share the same
        // (teamId, sessionId) so we can commit them in one WriteBatch.
        if (entry.actionType == 'MARK_ATTENDANCE') {
          final batchTeamId = entry.payload['teamId'] as String?;
          final batchSessionId = entry.payload['sessionId'] as String?;

          if (batchTeamId != null && batchSessionId != null) {
            // Gather run of entries for the same session.
            final batchEntries = <SyncEntry>[];
            int j = i;
            while (j < entries.length &&
                entries[j].actionType == 'MARK_ATTENDANCE' &&
                entries[j].payload['teamId'] == batchTeamId &&
                entries[j].payload['sessionId'] == batchSessionId &&
                entries[j].retryCount < _maxRetries) {
              batchEntries.add(entries[j]);
              j++;
            }

            // Attempt the batch commit.
            try {
              await _attendanceRepository.syncBatchedMarks(
                teamId: batchTeamId,
                sessionId: batchSessionId,
                payloads: batchEntries.map((e) => e.payload).toList(),
              );

              // Success: remove all entries in the batch from the queue.
              for (final batchEntry in batchEntries) {
                await box.delete(batchEntry.id);
              }
              processedEntries += batchEntries.length;
              developer.log(
                'Batched ${batchEntries.length} MARK_ATTENDANCE entries for '
                'session $batchSessionId.',
                name: 'SyncService',
              );
            } catch (e) {
              developer.log(
                'Batch MARK_ATTENDANCE failed for session $batchSessionId. '
                'Retrying individually. Error: $e',
                name: 'SyncService',
              );
              // Increment retryCount on every entry in the failed batch.
              for (final batchEntry in batchEntries) {
                batchEntry.retryCount++;
                await batchEntry.save();
              }
              _statusController.add(
                SyncStatus.error(
                  'حدث خطأ أثناء مزامنة بيانات الحضور. سيتم المحاولة لاحقاً.',
                ),
              );
              // Apply exponential backoff based on the first entry's retry count.
              final backoffMs =
                  _baseBackoffMs *
                  (1 << (batchEntries.first.retryCount - 1).clamp(0, 10));
              await Future<void>.delayed(Duration(milliseconds: backoffMs));
            }

            _statusController.add(
              SyncStatus.processing(
                totalEntries - processedEntries,
                totalEntries,
              ),
            );
            i = j; // Advance past the entire batch window.
            continue;
          }
        }

        // ── All other action types — individual dispatch ──────────────────
        try {
          await _executeEntry(entry);
          await box.delete(entry.id);
          processedEntries++;
          _statusController.add(
            SyncStatus.processing(
              totalEntries - processedEntries,
              totalEntries,
            ),
          );
        } catch (e) {
          developer.log(
            'Failed to process SyncEntry ${entry.id} '
            '(retry ${entry.retryCount}): $e',
            name: 'SyncService',
          );
          entry.retryCount++;
          await entry.save();

          _statusController.add(
            SyncStatus.error(
              'حدث خطأ أثناء مزامنة بعض البيانات. سيتم المحاولة لاحقاً.',
            ),
          );

          // Exponential backoff: 500ms, 1s, 2s, 4s, 8s …
          // `clamp(0, 10)` guards against negative shifts on first failure
          // (retryCount was 0 before the increment above).
          final backoffMs =
              _baseBackoffMs * (1 << (entry.retryCount - 1).clamp(0, 10));
          await Future<void>.delayed(Duration(milliseconds: backoffMs));
        }

        i++;
      }

      if (box.isEmpty) {
        _statusController.add(SyncStatus.success());
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Routes the payload to the appropriate Firestore repository.
  Future<void> _executeEntry(SyncEntry entry) async {
    switch (entry.actionType) {
      case 'MARK_ATTENDANCE':
        await _attendanceRepository.syncOfflineMark(entry.payload);
        developer.log(
          'Processing MARK_ATTENDANCE: ${entry.payload}',
          name: 'SyncService',
        );
        break;

      case 'UPSERT_STUDENT':
        await _studentRepository.syncOfflineUpsert(entry.payload);
        developer.log(
          'Processing UPSERT_STUDENT: ${entry.payload}',
          name: 'SyncService',
        );
        break;

      case 'ARCHIVE_STUDENT':
        await _studentRepository.syncOfflineArchive(entry.payload);
        developer.log(
          'Processing ARCHIVE_STUDENT: ${entry.payload}',
          name: 'SyncService',
        );
        break;

      case 'RESTORE_STUDENT':
        await _studentRepository.syncOfflineRestore(entry.payload);
        developer.log(
          'Processing RESTORE_STUDENT: ${entry.payload}',
          name: 'SyncService',
        );
        break;

      case 'UPDATE_RESULT':
        await _resultsRepository.syncOfflineUpdate(entry.payload);
        developer.log(
          'Processing UPDATE_RESULT: ${entry.payload}',
          name: 'SyncService',
        );
        break;

      case 'CREATE_SESSION':
        await _sessionRepository.syncOfflineSessionCreation(entry.payload);
        developer.log(
          'Processing CREATE_SESSION: ${entry.payload}',
          name: 'SyncService',
        );
        break;

      case 'CLOSE_SESSION':
        await _sessionRepository.syncOfflineCloseSession(entry.payload);
        developer.log(
          'Processing CLOSE_SESSION: ${entry.payload}',
          name: 'SyncService',
        );
        break;

      case 'CREATE_PASTORAL_RECORD':
        await _pastoralRepository.syncOfflineCreate(entry.payload);
        developer.log(
          'Processing CREATE_PASTORAL_RECORD: ${entry.payload}',
          name: 'SyncService',
        );
        break;

      // Add other feature-specific action types here

      default:
        developer.log(
          'Unknown actionType: ${entry.actionType}',
          name: 'SyncService',
        );
        // Throw an error to trigger retry logic, or discard it if irrecoverable
        throw UnimplementedError(
          'Unknown sync action type: ${entry.actionType}',
        );
    }
  }

  /// Cleans up stream subscriptions
  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
  }
}

import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_session_repository.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/results/domain/repos/i_results_repository.dart';
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

  const SyncStatus({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.totalCount = 0,
    this.hasError = false,
    this.errorMessage,
  });

  factory SyncStatus.idle() => const SyncStatus();

  factory SyncStatus.processing(int pending, int total) =>
      SyncStatus(isSyncing: true, pendingCount: pending, totalCount: total);

  factory SyncStatus.success() => const SyncStatus();

  factory SyncStatus.error(String message) =>
      SyncStatus(hasError: true, errorMessage: message);
}

/// Centralized offline sync engine.
///
/// Manages a FIFO queue of [SyncEntry] items in Hive and attempts to push
/// them to Firestore whenever network connectivity is available.
class SyncService {
  static const String _boxName = 'sync_queue_box';
  static const int _maxRetries = 5;

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isProcessing = false;

  final _statusController = StreamController<SyncStatus>.broadcast();

  /// Stream of sync status updates for the UI to listen to.
  Stream<SyncStatus> get statusStream => _statusController.stream;

  SyncService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  /// Initializes the Hive box and starts listening to connectivity changes.
  Future<void> init() async {
    // Note: Ensure Hive.registerAdapter(SyncEntryAdapter()) is called in main.dart
    await Hive.openBox<SyncEntry>(_boxName);

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
            'sync_one_off_${DateTime.now().millisecondsSinceEpoch}',
            'offline_sync_task',
            constraints: Constraints(networkType: NetworkType.connected),
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

  /// Processes the queue sequentially (FIFO).
  Future<void> processQueue() async {
    if (_isProcessing) return;

    final box = Hive.box<SyncEntry>(_boxName);
    if (box.isEmpty) return; // Nothing to sync

    _isProcessing = true;
    final int totalEntries = box.length;
    int processedEntries = 0;

    _statusController.add(SyncStatus.processing(totalEntries, totalEntries));

    try {
      // Get all entries sorted by creation time
      final entries = box.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      for (final entry in entries) {
        // Re-verify network before processing each entry
        final results = await _connectivity.checkConnectivity();
        if (results.contains(ConnectivityResult.none)) {
          developer.log(
            'Network lost, pausing sync queue.',
            name: 'SyncService',
          );
          _statusController.add(
            SyncStatus.error('انقطع الاتصال بالإنترنت أثناء المزامنة.'),
          );
          break;
        }

        if (entry.retryCount >= _maxRetries) {
          developer.log(
            'SyncEntry ${entry.id} reached max retries. Marking failed/deleting.',
            name: 'SyncService',
          );
          // To prevent blocking the queue forever, we drop the failing entry.
          // In a fully robust system, you might move it to a 'dead-letter' box.
          await box.delete(entry.id);
          processedEntries++;
          _statusController.add(
            SyncStatus.processing(
              totalEntries - processedEntries,
              totalEntries,
            ),
          );
          continue;
        }

        try {
          await _executeEntry(entry);
          // Success: remove from queue
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
            'Failed to process SyncEntry ${entry.id}. Retry: ${entry.retryCount}',
            error: e,
            name: 'SyncService',
          );
          // Increment retry count and save back to Hive
          entry.retryCount++;
          await entry.save();

          _statusController.add(
            SyncStatus.error(
              'حدث خطأ أثناء مزامنة بعض البيانات. سيتم المحاولة لاحقاً.',
            ),
          );
          // Exponential backoff logic could optionally be inserted here.
          // For now, we continue to the next item or break depending on the error severity.
        }
      }

      // If we finished the loop and the box is empty, it was a success.
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
        await getIt<IAttendanceRepository>().syncOfflineMark(entry.payload);
        developer.log(
          'Processing MARK_ATTENDANCE: ${entry.payload}',
          name: 'SyncService',
        );
        break;

      case 'UPSERT_STUDENT':
        await getIt<IStudentRepository>().syncOfflineUpsert(entry.payload);
        developer.log(
          'Processing UPSERT_STUDENT: ${entry.payload}',
          name: 'SyncService',
        );
        break;

      case 'ARCHIVE_STUDENT':
        await getIt<IStudentRepository>().syncOfflineArchive(entry.payload);
        developer.log(
          'Processing ARCHIVE_STUDENT: ${entry.payload}',
          name: 'SyncService',
        );
        break;

      case 'RESTORE_STUDENT':
        await getIt<IStudentRepository>().syncOfflineRestore(entry.payload);
        developer.log(
          'Processing RESTORE_STUDENT: ${entry.payload}',
          name: 'SyncService',
        );
        break;

      case 'UPDATE_RESULT':
        await getIt<IResultsRepository>().syncOfflineUpdate(entry.payload);
        developer.log(
          'Processing UPDATE_RESULT: ${entry.payload}',
          name: 'SyncService',
        );
        break;

      case 'CREATE_SESSION':
        await getIt<AttendanceSessionRepository>().syncOfflineSessionCreation(
          entry.payload,
        );
        developer.log(
          'Processing CREATE_SESSION: ${entry.payload}',
          name: 'SyncService',
        );
        break;

      case 'CLOSE_SESSION':
        await getIt<AttendanceSessionRepository>().syncOfflineCloseSession(
          entry.payload,
        );
        developer.log(
          'Processing CLOSE_SESSION: ${entry.payload}',
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

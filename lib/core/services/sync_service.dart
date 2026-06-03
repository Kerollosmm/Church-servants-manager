import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/dead_letter_queue.dart';
import 'package:church_management_system/core/services/sync_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

/// Centralized offline sync engine using the Outbox pattern.
class SyncService {
  static const int _maxRetries = 5;
  static const int _baseBackoffMs = 500;
  final Connectivity _connectivity;
  final DeadLetterQueue _dlq;
  final Map<String, SyncHandler> _handlers;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isProcessing = false;

  String? _activeUserId;
  Box<SyncEntry>? _activeBox;
  final _statusController = StreamController<SyncStatus>.broadcast();
  final _random = Random();

  /// Stream of sync status updates for the UI to listen to.
  Stream<SyncStatus> get statusStream => _statusController.stream;
  SyncService({
    required DeadLetterQueue deadLetterQueue,
    required Map<String, SyncHandler> handlers,
    Connectivity? connectivity,
  }) : _dlq = deadLetterQueue,
       _handlers = handlers,
       _connectivity = connectivity ?? Connectivity();

  /// Gets the name of the Hive box for a specific user.
  String _boxNameForUser(String userId) => 'sync_queue_$userId';

  /// Sets the active authenticated user and mounts their specific queue.
  Future<void> setAuthenticatedUser(String? userId) async {
    if (_activeUserId == userId && _activeBox != null) return;
    if (_activeBox != null && _activeBox!.isOpen) {
      await _activeBox!.close();
    }
    _activeUserId = userId;
    if (userId != null) {
      final boxName = _boxNameForUser(userId);
      _activeBox = await Hive.openBox<SyncEntry>(
        boxName,
        compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
      );
      developer.log('Mounted sync queue box: $boxName', name: 'SyncService');

      // Auto-trigger sync on user switch if connected
      final results = await _connectivity.checkConnectivity();
      if (!results.contains(ConnectivityResult.none)) {
        unawaited(processQueue());
      }
    } else {
      _activeBox = null;
      developer.log('Dismounted sync queue', name: 'SyncService');
    }
  }

  /// Initializes the Hive box and starts listening to connectivity changes.
  Future<void> init() async {
    await _dlq.init();
    // Listen for network changes to auto-trigger the sync queue
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (!results.contains(ConnectivityResult.none)) {
        unawaited(processQueue());
      }
    });
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    if (!results.contains(ConnectivityResult.none)) {
      unawaited(processQueue());
    }
  }

  /// Lightweight bootstrap used exclusively by the Workmanager background task.
  Future<void> initAndProcessOnce() async {
    await _dlq.init();
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    if (firebaseUid != null) {
      await setAuthenticatedUser(firebaseUid);
      await processQueue();
    }
  }

  /// Adds a new mutation entry to the sync queue.
  Future<void> enqueue(SyncEntry entry) async {
    if (_activeUserId == null) {
      developer.log(
        'Warning: Attempted to enqueue SyncEntry when no user is authenticated',
        name: 'SyncService',
      );
      return;
    }
    try {
      final box =
          _activeBox ??
          await Hive.openBox<SyncEntry>(
            _boxNameForUser(_activeUserId!),
            compactionStrategy: (entries, deletedEntries) =>
                deletedEntries > 50,
          );

      // Ensure the entry is stamped with the active userId
      final stampedEntry = SyncEntry(
        id: entry.id,
        actionType: entry.actionType,
        payload: entry.payload,
        createdAt: entry.createdAt,
        retryCount: entry.retryCount,
        failedAt: entry.failedAt,
        userId: _activeUserId,
        lastErrorMessage: entry.lastErrorMessage,
      );
      await box.put(stampedEntry.id, stampedEntry);
      _statusController.add(SyncStatus.idle());
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

  /// Evicts/removes an entry from the sync queue box immediately.
  /// Used when an immediate online write succeeds to prevent double sync.
  Future<void> dequeue(String entryId) async {
    if (_activeUserId == null || _activeBox == null) return;
    try {
      final box = _activeBox;
      if (box != null && box.isOpen) {
        await box.delete(entryId);
        developer.log(
          'Evicted successfully processed entry $entryId from queue',
          name: 'SyncService',
        );
      }
    } catch (e, stack) {
      developer.log(
        'Failed to dequeue SyncEntry $entryId',
        error: e,
        stackTrace: stack,
        name: 'SyncService',
      );
    }
  }

  /// Processes the active user's queue sequentially (FIFO) with Consecutive Chunking.
  Future<void> processQueue() async {
    if (_isProcessing) return;
    if (_activeUserId == null || _activeBox == null) return;
    final targetBox = _activeBox;
    if (targetBox == null || !targetBox.isOpen) return;
    if (targetBox.isEmpty) return;
    _isProcessing = true;
    // Snapshot length BEFORE we start — used for progress reporting.
    final int totalEntries = targetBox.length;
    int processedEntries = 0;
    _statusController.add(SyncStatus.processing(totalEntries, totalEntries));
    try {
      // FIFO order: sort ascending by creation time.
      final entries = targetBox.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      int i = 0;
      while (i < entries.length) {
        // Re-check box state each iteration to prevent stall conditions
        if (_activeUserId == null || _activeBox == null || !targetBox.isOpen) {
          developer.log(
            'Active user or box changed/closed mid-flight — halting sync queue processing.',
            name: 'SyncService',
          );
          break;
        }
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
        // DLQ threshold protection
        if (entry.retryCount >= _maxRetries) {
          await _evictToDlq(entry, targetBox);
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
        // Consecutive Chunking for MARK_ATTENDANCE
        if (entry.actionType == 'MARK_ATTENDANCE') {
          final teamId = entry.payload['teamId'] as String?;
          final sessionId = entry.payload['sessionId'] as String?;
          if (teamId != null && sessionId != null) {
            final batchEntries = <SyncEntry>[];
            int j = i;
            while (j < entries.length &&
                entries[j].actionType == 'MARK_ATTENDANCE' &&
                entries[j].payload['teamId'] == teamId &&
                entries[j].payload['sessionId'] == sessionId &&
                entries[j].retryCount < _maxRetries &&
                batchEntries.length < 400) {
              batchEntries.add(entries[j]);
              j++;
            }
            try {
              final handler = _handlers['MARK_ATTENDANCE'];
              if (handler == null) {
                throw UnimplementedError(
                  'No handler registered for MARK_ATTENDANCE',
                );
              }
              // Capture local box reference before the async call
              final batchBox = _activeBox;
              await handler.executeBatch(batchEntries);

              // Success: remove all successfully synced entries immediately using batchBox
              if (batchBox != null && batchBox.isOpen) {
                for (final batchEntry in batchEntries) {
                  await batchBox.delete(batchEntry.id);
                  processedEntries++;
                }
              }
              developer.log(
                'Batched ${batchEntries.length} MARK_ATTENDANCE entries for session $sessionId.',
                name: 'SyncService',
              );
            } catch (e) {
              developer.log(
                'Batch MARK_ATTENDANCE failed for session $sessionId. Falling back to individual runs. Error: $e',
                name: 'SyncService',
              );

              // Fallback: execute entries individually
              for (final batchEntry in batchEntries) {
                // Check connectivity before each execution
                final currentConn = await _connectivity.checkConnectivity();
                if (currentConn.contains(ConnectivityResult.none)) {
                  developer.log(
                    'Network lost during individual fallback. Halting execution.',
                    name: 'SyncService',
                  );
                  break;
                }
                try {
                  final handler = _handlers['MARK_ATTENDANCE'];
                  if (handler == null) throw UnimplementedError();
                  // Capture local box reference before the async call
                  final individualBox = _activeBox;
                  await handler.execute(batchEntry);
                  if (individualBox != null && individualBox.isOpen) {
                    await individualBox.delete(batchEntry.id);
                  }
                  processedEntries++;
                } catch (individualError) {
                  // Intercept network outage in individual fallback loop
                  final currentConn = await _connectivity.checkConnectivity();
                  final isNoInternet = currentConn.contains(
                    ConnectivityResult.none,
                  );

                  bool isNetworkError = isNoInternet;
                  if (individualError is FirebaseException &&
                      individualError.code == 'unavailable') {
                    isNetworkError = true;
                  }
                  if (isNetworkError) {
                    developer.log(
                      'Network issue (isNoInternet: $isNoInternet, firebase unavailable: ${individualError is FirebaseException && individualError.code == 'unavailable'}) during fallback. Halting execution without penalizing remaining items.',
                      error: individualError,
                      name: 'SyncService',
                    );
                    break; // immediately halt loop, retaining original retryCount of current and remaining items
                  }
                  final errorBox = _activeBox;
                  await _handleEntryFailure(
                    batchEntry,
                    individualError,
                    errorBox,
                  );
                  await _applyBackoff(batchEntry.retryCount);
                }
              }
            }
            _statusController.add(
              SyncStatus.processing(
                totalEntries - processedEntries,
                totalEntries,
              ),
            );
            i = j; // Advance past the batch window
            continue;
          }
        }
        // All other action types — individual execution
        try {
          final handler = _handlers[entry.actionType];
          if (handler == null) {
            throw UnimplementedError(
              'No sync handler registered for action: ${entry.actionType}',
            );
          }
          // Capture local box reference before the async call
          final individualBox = _activeBox;
          await handler.execute(entry);
          if (individualBox != null && individualBox.isOpen) {
            await individualBox.delete(entry.id);
          }
          processedEntries++;
          _statusController.add(
            SyncStatus.processing(
              totalEntries - processedEntries,
              totalEntries,
            ),
          );
        } catch (e) {
          final errorBox = _activeBox;
          await _handleEntryFailure(entry, e, errorBox);
          await _applyBackoff(entry.retryCount);
        }
        i++;
      }
      if (targetBox.isOpen && targetBox.isEmpty) {
        _statusController.add(SyncStatus.success());
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Handles incrementing retry count, failure logging, and DLQ eviction.
  Future<void> _handleEntryFailure(
    SyncEntry entry,
    dynamic error,
    Box<SyncEntry>? box,
  ) async {
    if (box == null || !box.isOpen) return;
    developer.log(
      'Failed to process SyncEntry ${entry.id} (retry count ${entry.retryCount}): $error',
      name: 'SyncService',
    );
    entry
      ..retryCount = entry.retryCount + 1
      ..failedAt = DateTime.now()
      ..lastErrorMessage = error.toString();
    if (entry.retryCount >= _maxRetries) {
      await _evictToDlq(entry, box);
    } else {
      await box.put(entry.id, entry);
      _statusController.add(
        SyncStatus.error(
          'حدث خطأ أثناء مزامنة بعض البيانات. سيتم المحاولة لاحقاً.',
        ),
      );
    }
  }

  /// Evicts a failed entry atomically to the DLQ.
  Future<void> _evictToDlq(SyncEntry entry, Box<SyncEntry> box) async {
    if (!box.isOpen) return;
    developer.log(
      'SyncEntry ${entry.id} exceeded max retries ($_maxRetries). Evicting to DLQ.',
      name: 'SyncService',
    );
    entry.failedAt = DateTime.now();
    // Create a clean copy to prevent HiveObject internal binding errors
    // when storing the entry in the DeadLetterQueue box.
    final cleanCopy = SyncEntry(
      id: entry.id,
      actionType: entry.actionType,
      payload: Map<String, dynamic>.from(entry.payload),
      createdAt: entry.createdAt,
      retryCount: entry.retryCount,
      failedAt: entry.failedAt,
      userId: entry.userId,
      lastErrorMessage: entry.lastErrorMessage,
    );
    await _dlq.add(cleanCopy);
    await box.delete(entry.id);
    _statusController.add(SyncStatus.dlqEviction(entry.id, entry.actionType));
  }

  /// Applies exponential backoff delay with random jitter.
  Future<void> _applyBackoff(int retryCount) async {
    final exponentialDelay =
        _baseBackoffMs * (1 << (retryCount - 1).clamp(0, 10));
    final jitter = _random.nextInt(200); // 0-199ms random jitter
    final finalDelay = exponentialDelay + jitter;
    await Future<void>.delayed(Duration(milliseconds: finalDelay));
  }

  /// Cleans up subscriptions.
  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
  }
}

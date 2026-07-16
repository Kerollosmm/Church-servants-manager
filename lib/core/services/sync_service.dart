import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/dead_letter_queue.dart';
import 'package:church_management_system/core/services/sync_handler.dart';
import 'package:church_management_system/core/utils/sync_error_classifier.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:workmanager/workmanager.dart';

/// Represents the current state of the sync engine.
class SyncEngineStatus {
  final bool isSyncing;
  final int pendingCount;
  final int totalCount;
  final bool hasError;
  final String? errorMessage;

  /// Non-null when a [SyncEntry] was moved to the dead-letter queue.
  /// The UI must surface a manual-intervention warning in this case.
  final String? dlqEntryId;
  final String? dlqActionType;
  const SyncEngineStatus({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.totalCount = 0,
    this.hasError = false,
    this.errorMessage,
    this.dlqEntryId,
    this.dlqActionType,
  });
  factory SyncEngineStatus.idle() => const SyncEngineStatus();
  factory SyncEngineStatus.processing(int pending, int total) =>
      SyncEngineStatus(
        isSyncing: true,
        pendingCount: pending,
        totalCount: total,
      );
  factory SyncEngineStatus.success() => const SyncEngineStatus();
  factory SyncEngineStatus.error(String message) =>
      SyncEngineStatus(hasError: true, errorMessage: message);

  /// Emitted when an entry has been evicted to the dead-letter queue.
  factory SyncEngineStatus.dlqEviction(String entryId, String actionType) =>
      SyncEngineStatus(dlqEntryId: entryId, dlqActionType: actionType);
}

/// Centralized offline sync engine using the Outbox pattern.
class SyncService {
  static const String periodicTaskUniqueName = 'csms_sync_task_id';
  static const String oneOffTaskUniqueName = 'csms_sync_offline_queue';
  static const String taskName = 'offline_sync_task';

  static const int _maxRetries = 5;
  static const int _baseBackoffMs = 1000;
  final Connectivity _connectivity;
  final DeadLetterQueue _dlq;
  final Map<String, SyncHandler> _handlers;
  final Duration Function(int)? _backoffProvider;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isProcessing = false;
  bool _hasPendingTriggers = false;

  String? _activeUserId;
  Box<SyncEntry>? _activeBox;
  final _statusController = StreamController<SyncEngineStatus>.broadcast();
  final _random = Random();

  /// Stream of sync status updates for the UI to listen to.
  Stream<SyncEngineStatus> get statusStream => _statusController.stream;

  /// Returns the current number of enqueued sync entries for the active user.
  int get pendingCount =>
      (_activeBox != null && _activeBox!.isOpen) ? _activeBox!.length : 0;

  /// Returns whether the sync queue is currently processing.
  bool get isProcessing => _isProcessing;

  /// Returns whether the active user's sync queue box is successfully mounted.
  bool get isBoxMounted => _activeBox != null && _activeBox!.isOpen;

  SyncService({
    required DeadLetterQueue deadLetterQueue,
    required Map<String, SyncHandler> handlers,
    Connectivity? connectivity,
    Duration Function(int)? backoffProvider,
  }) : _dlq = deadLetterQueue,
       _handlers = handlers,
       _connectivity = connectivity ?? Connectivity(),
       _backoffProvider = backoffProvider;

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
      try {
        _activeBox = await Hive.openBox<SyncEntry>(
          boxName,
          compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
        );
        developer.log('Mounted sync queue box: $boxName', name: 'SyncService');
      } catch (e, stack) {
        developer.log(
          'Failed to mount sync queue box: $boxName',
          error: e,
          stackTrace: stack,
          name: 'SyncService',
        );
        _statusController.add(
          SyncEngineStatus.error(
            'فشل في تحميل خزان المزامنة المحلي. الرجاء إعادة تسجيل الدخول.',
          ),
        );
        rethrow;
      }

      // Register periodic sync task for this user
      try {
        await Workmanager().registerPeriodicTask(
          periodicTaskUniqueName,
          taskName,
          frequency: const Duration(minutes: 15),
          constraints: Constraints(networkType: NetworkType.connected),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
          inputData: {'userId': userId},
        );
        developer.log(
          'Registered periodic Workmanager task for user: $userId',
          name: 'SyncService',
        );
      } catch (e) {
        developer.log(
          'Failed to register periodic Workmanager task',
          error: e,
          name: 'SyncService',
        );
      }

      // Auto-trigger sync on user switch if connected
      final results = await _connectivity.checkConnectivity();
      if (!results.contains(ConnectivityResult.none)) {
        unawaited(processQueue());
      }
    } else {
      _activeBox = null;
      developer.log('Dismounted sync queue', name: 'SyncService');
      try {
        await Workmanager().cancelByUniqueName(periodicTaskUniqueName);
        await Workmanager().cancelByUniqueName(oneOffTaskUniqueName);
        developer.log(
          'Cancelled all Workmanager tasks on logout',
          name: 'SyncService',
        );
      } catch (e) {
        developer.log(
          'Failed to cancel Workmanager tasks on logout',
          error: e,
          name: 'SyncService',
        );
      }
    }
    _statusController.add(SyncEngineStatus.idle());
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
      _activeBox ??= await Hive.openBox<SyncEntry>(
        _boxNameForUser(_activeUserId!),
        compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
      );
      final box = _activeBox!;

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
      _statusController.add(SyncEngineStatus.idle());

      // Attempt to sync immediately if online
      final results = await _connectivity.checkConnectivity();
      if (!results.contains(ConnectivityResult.none)) {
        unawaited(processQueue());
      } else {
        try {
          await Workmanager().registerOneOffTask(
            oneOffTaskUniqueName,
            taskName,
            constraints: Constraints(networkType: NetworkType.connected),
            existingWorkPolicy: ExistingWorkPolicy.replace,
            inputData: {'userId': _activeUserId!},
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
        if (!_isProcessing) {
          _statusController.add(SyncEngineStatus.idle());
        }
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

  /// Retries all entries currently in the dead-letter queue by re-enqueuing them.
  Future<void> retryDlq() async {
    if (_activeUserId == null) return;
    _activeBox ??= await Hive.openBox<SyncEntry>(
      _boxNameForUser(_activeUserId!),
      compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
    );
    final box = _activeBox!;
    if (!box.isOpen) return;

    try {
      final dlqEntries = _dlq.getAll();
      if (dlqEntries.isEmpty) return;

      for (final entry in dlqEntries) {
        final resetEntry = SyncEntry(
          id: entry.id,
          actionType: entry.actionType,
          payload: Map<String, dynamic>.from(entry.payload),
          createdAt: entry.createdAt,
          userId: _activeUserId,
        );
        await box.put(resetEntry.id, resetEntry);
        await _dlq.remove(entry.id);
      }

      // Trigger queue processing
      unawaited(processQueue());
    } catch (e) {
      developer.log('Failed to retry DLQ: $e', name: 'SyncService');
    }
  }

  /// Processes the active user's queue sequentially (FIFO) with Consecutive Chunking.
  Future<void> processQueue() async {
    if (_isProcessing) {
      _hasPendingTriggers = true;
      return;
    }
    if (_activeUserId == null || _activeBox == null) return;
    final targetBox = _activeBox;
    if (targetBox == null || !targetBox.isOpen) return;
    if (targetBox.isEmpty) return;
    _isProcessing = true;

    int totalEntries = targetBox.length;
    _statusController.add(
      SyncEngineStatus.processing(targetBox.length, totalEntries),
    );
    try {
      while (targetBox.isOpen && targetBox.isNotEmpty) {
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
            'Network lost — pausing sync queue.',
            name: 'SyncService',
          );
          _statusController.add(
            SyncEngineStatus.error('انقطع الاتصال بالإنترنت أثناء المزامنة.'),
          );
          break;
        }

        // Get sorted list of current entries in the box
        final entries = targetBox.values.toList()
          ..sort((a, b) {
            final timeCompare = a.createdAt.compareTo(b.createdAt);
            if (timeCompare != 0) return timeCompare;
            return a.id.compareTo(b.id);
          });

        if (entries.isEmpty) break;
        final entry = entries.first;

        // Dynamically update totalEntries if the box length grows
        if (targetBox.length > totalEntries) {
          totalEntries = targetBox.length;
        }

        // DLQ threshold protection
        if (entry.retryCount >= _maxRetries) {
          await _evictToDlq(entry, targetBox);
          if (!targetBox.isOpen) break;
          _statusController.add(
            SyncEngineStatus.processing(targetBox.length, totalEntries),
          );
          continue;
        }

        // Consecutive Chunking for MARK_ATTENDANCE
        if (entry.actionType == 'MARK_ATTENDANCE') {
          final teamId = entry.payload['teamId'] as String?;
          final sessionId = entry.payload['sessionId'] as String?;
          if (teamId != null && sessionId != null) {
            final batchEntries = <SyncEntry>[];
            int j = 0;
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
                      'Network issue (isNoInternet: $isNoInternet) during fallback. Halting execution without penalizing remaining items.',
                      error: individualError,
                      name: 'SyncService',
                    );
                    _isProcessing = false;
                    return; // immediately halt processQueue, retaining original retryCount of current and remaining items
                  }
                  final errorBox = _activeBox;
                  await _handleEntryFailure(
                    batchEntry,
                    individualError,
                    errorBox,
                  );
                  // Apply backoff before halting so a retried entry (with its
                  // newly-bumped retryCount) doesn't immediately re-enter the
                  // queue and hammer Firestore on repeated failures. Tests pass
                  // backoffProvider: (_) => Duration.zero to keep this fast.
                  await _applyBackoff(batchEntry.retryCount + 1);
                  _isProcessing = false;
                  return;
                }
              }
            }
            if (!targetBox.isOpen) break;
            _statusController.add(
              SyncEngineStatus.processing(targetBox.length, totalEntries),
            );
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
          if (!targetBox.isOpen) break;
          _statusController.add(
            SyncEngineStatus.processing(targetBox.length, totalEntries),
          );
        } catch (e) {
          final errorBox = _activeBox;
          await _handleEntryFailure(entry, e, errorBox);
          // See comment above — same backoff-on-retry intent for the individual
          // handler failure path.
          await _applyBackoff(entry.retryCount + 1);
          _isProcessing = false;
          return;
        }
      }
      if (targetBox.isOpen && targetBox.isEmpty) {
        _statusController.add(SyncEngineStatus.success());
      }
    } finally {
      if (_hasPendingTriggers) {
        _hasPendingTriggers = false;
        _isProcessing = false;
        unawaited(processQueue());
      } else {
        _isProcessing = false;
      }
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
    final isRetriable = SyncErrorClassifier.isRetriable(error);
    final updated = SyncEntry(
      id: entry.id,
      actionType: entry.actionType,
      payload: entry.payload,
      createdAt: entry.createdAt,
      retryCount: isRetriable ? entry.retryCount + 1 : _maxRetries,
      failedAt: DateTime.now(),
      userId: entry.userId,
      lastErrorMessage: error.toString(),
    );
    if (updated.retryCount >= _maxRetries) {
      await _evictToDlq(updated, box);
      if (!isRetriable) {
        _statusController.add(
          SyncEngineStatus.error(
            'فشل المزامنة بشكل دائم بسبب صلاحيات المستخدم أو خطأ في البيانات.',
          ),
        );
      }
    } else {
      await box.put(updated.id, updated);
      _statusController.add(
        SyncEngineStatus.error(
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
    // Best-effort atomicity: DLQ write FIRST, then queue delete.
    // If crash occurs between these two operations, the entry will
    // exist in BOTH queues — deduplication on next run is acceptable.
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
    _statusController.add(
      SyncEngineStatus.dlqEviction(entry.id, entry.actionType),
    );
  }

  /// Applies exponential backoff delay with random jitter.
  Future<void> _applyBackoff(int retryCount) async {
    if (_backoffProvider != null) {
      await Future<void>.delayed(_backoffProvider(retryCount));
      return;
    }
    final exponentialDelay =
        _baseBackoffMs * (1 << (retryCount - 1).clamp(0, 5));
    final cappedDelay = exponentialDelay.clamp(0, 30000); // cap at 30s
    final jitter = _random.nextInt(1001); // 0-1000ms random jitter
    final finalDelay = cappedDelay + jitter;
    await Future<void>.delayed(Duration(milliseconds: finalDelay));
  }

  /// Cleans up subscriptions.
  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
  }
}

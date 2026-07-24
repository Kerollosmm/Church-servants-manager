import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/dead_letter_queue.dart';
import 'package:church_management_system/core/services/sync_handler.dart';

const int kMaxSyncRetries = 3;

/// Core service responsible for processing pending offline sync entries.
class SyncService {
  final Map<String, SyncHandler> _handlers;
  final DeadLetterQueue _deadLetterQueue;

  SyncService({
    required Map<String, SyncHandler> handlers,
    required DeadLetterQueue deadLetterQueue,
  })  : _handlers = handlers,
        _deadLetterQueue = deadLetterQueue;

  Future<void> processEntry(SyncEntry entry, {required Function(String recordId, SyncStatus status) updateLocalStatus, required Function(String entryId) removeFromQueue, required Function(String entryId) incrementRetry}) async {
    try {
      final handler = _handlers[entry.entityType];
      if (handler == null) {
        throw Exception('No handler registered for entityType ${entry.entityType}');
      }

      await handler.execute(entry);
      await updateLocalStatus(entry.recordId, SyncStatus.synced);
      await removeFromQueue(entry.id);
      developer.log('Successfully synced entry: ${entry.id} (${entry.recordId})');
    } catch (e, stackTrace) {
      developer.log('Error syncing entry ${entry.id}: $e', stackTrace: stackTrace);
      if (entry.retryCount >= kMaxSyncRetries) {
        await updateLocalStatus(entry.recordId, SyncStatus.failed);
        await _deadLetterQueue.addFailedEntry(entry, e.toString());
        await removeFromQueue(entry.id);
        developer.log('Entry ${entry.id} moved to DLQ after $kMaxSyncRetries failed attempts');
      } else {
        await incrementRetry(entry.id);
      }
    }
  }
}

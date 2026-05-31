import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/sync_handler.dart';
import 'package:church_management_system/features/results/domain/repos/i_results_repository.dart';

/// Handles synchronization of results-related mutations.
class ResultsSyncHandler implements SyncHandler {
  final IResultsRepository _resultsRepository;
  ResultsSyncHandler(this._resultsRepository);
  @override
  Future<void> execute(SyncEntry entry) async {
    if (entry.actionType == 'UPDATE_RESULT') {
      await _resultsRepository.syncOfflineUpdate(entry.payload);
    } else {
      throw UnimplementedError(
        'Action type ${entry.actionType} not supported by ResultsSyncHandler',
      );
    }
  }

  @override
  Future<void> executeBatch(List<SyncEntry> entries) async {
    for (final entry in entries) {
      await execute(entry);
    }
  }
}

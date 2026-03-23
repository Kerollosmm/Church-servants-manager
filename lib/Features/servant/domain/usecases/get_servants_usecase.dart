import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// FIX [P1]: extracted servant pagination/loading behind a use case.
class GetServantsUseCase {
  const GetServantsUseCase(this._repository);

  final ServantDataRepository _repository;

  Future<ServantsPage> call({
    int limit = 50,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    bool includeArchived = false,
  }) {
    return _repository.getServantsPage(
      limit: limit,
      lastDocument: lastDocument,
      includeArchived: includeArchived,
    );
  }
}

import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_management_system/features/servant/domain/failures/servant_failures.dart';

// FIX [P1]: extracted servant restore orchestration behind a use case.
class RestoreServantUseCase {
  const RestoreServantUseCase(
    this._repository,
    this._adminUserProvisioningService,
  );

  final ServantDataRepository _repository;
  final AdminUserProvisioningService _adminUserProvisioningService;

  Future<ServantModel> call(String docId) async {
    final existing = await _repository.getServantById(
      docId,
      includeArchived: true,
    );
    if (existing == null) {
      throw const GenericServantFailure('لم يتم العثور على الخادم.');
    }
    await _repository.restoreServant(docId);
    final normalizedUid = existing.uid?.trim();
    if (normalizedUid != null && normalizedUid.isNotEmpty) {
      await _adminUserProvisioningService.restoreUser(uid: normalizedUid);
    }
    return existing;
  }
}

import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';

// FIX [P1]: extracted servant archive orchestration behind a use case.
class DeleteServantUseCase {
  const DeleteServantUseCase(
    this._repository,
    this._adminUserProvisioningService,
  );

  final ServantDataRepository _repository;
  final AdminUserProvisioningService _adminUserProvisioningService;

  Future<void> call(String docId, {required String performedByUid}) async {
    final existing = await _repository.getServantById(
      docId,
      includeArchived: true,
    );
    await _repository.deleteServant(docId, performedByUid: performedByUid);
    final normalizedUid = existing?.uid?.trim();
    if (normalizedUid != null && normalizedUid.isNotEmpty) {
      await _adminUserProvisioningService.archiveUser(uid: normalizedUid);
    }
  }
}

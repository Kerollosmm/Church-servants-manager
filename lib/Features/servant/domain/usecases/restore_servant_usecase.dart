import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
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

  Future<String> call(String docId, {required String performedByUid}) async {
    final existing = await _repository.getServantById(
      docId,
      includeArchived: true,
    );
    if (existing == null) {
      throw const GenericServantFailure('لم يتم العثور على الخادم.');
    }
    await _repository.restoreServant(docId, performedByUid: performedByUid);
    final normalizedUid = existing.uid?.trim();
    if (normalizedUid != null && normalizedUid.isNotEmpty) {
      return _adminUserProvisioningService.restoreUser(uid: normalizedUid);
    }
    return 'تمت استعادة الخادم بنجاح.';
  }
}

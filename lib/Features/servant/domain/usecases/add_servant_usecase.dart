import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';

// FIX [P1]: extracted servant creation/rollback orchestration behind a use case.
class AddServantUseCase {
  const AddServantUseCase(this._repository, this._adminUserProvisioningService);

  final ServantDataRepository _repository;
  final AdminUserProvisioningService _adminUserProvisioningService;

  Future<ServantModel> call({
    required ServantModel servant,
    String? email,
    String? password,
  }) async {
    AuthUser? createdAuthUser;
    try {
      createdAuthUser = await _createServantAuthUser(
        servant: servant,
        email: email,
        password: password,
      );
      final authUid = createdAuthUser?.uid;
      final servantWithUid = authUid != null
          ? servant.copyWith(uid: authUid, docID: authUid)
          : servant;
      final docId = await _repository.createServant(servantWithUid);
      return servantWithUid.copyWith(docID: docId);
    } catch (error) {
      if (createdAuthUser != null &&
          email != null &&
          email.isNotEmpty &&
          password != null &&
          password.isNotEmpty) {
        await _adminUserProvisioningService.rollbackCreatedUser(
          uid: createdAuthUser.uid,
          email: email,
          password: password,
        );
      }
      rethrow;
    }
  }

  Future<AuthUser?> _createServantAuthUser({
    required ServantModel servant,
    String? email,
    String? password,
  }) {
    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      return Future<AuthUser?>.value(null);
    }
    return _adminUserProvisioningService.createUser(
      email: email,
      password: password,
      name: servant.name,
      role: servant.role,
    );
  }
}

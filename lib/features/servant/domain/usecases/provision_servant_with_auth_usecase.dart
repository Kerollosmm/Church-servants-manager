import 'dart:developer' as developer;
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
import 'package:church_management_system/features/servant/domain/entities/servant.dart';
import 'package:church_management_system/features/servant/domain/repos/i_servant_repository.dart';

class ProvisionServantWithAuthUseCase {
  const ProvisionServantWithAuthUseCase({
    required IServantRepository servantRepository,
    required AdminUserProvisioningService provisioningService,
  }) : _servantRepository = servantRepository,
       _provisioningService = provisioningService;

  final IServantRepository _servantRepository;
  final AdminUserProvisioningService _provisioningService;

  bool _hasCredentials(String? email, String? password) {
    return email != null &&
        email.isNotEmpty &&
        password != null &&
        password.isNotEmpty;
  }

  Future<String> call({
    required Servant servant,
    String? email,
    String? password,
  }) async {
    AuthUser? createdAuthUser;
    try {
      if (_hasCredentials(email, password)) {
        createdAuthUser = await _provisioningService.createUser(
          email: email!,
          password: password!,
          name: servant.name,
          role: servant.role,
        );
      }

      final servantWithUid = createdAuthUser != null
          ? servant.copyWith(
              uid: createdAuthUser.uid,
              docID: createdAuthUser.uid,
            )
          : servant;

      return await _servantRepository.createServant(servantWithUid);
    } catch (e) {
      if (createdAuthUser != null && _hasCredentials(email, password)) {
        try {
          await _provisioningService.rollbackCreatedUser(
            uid: createdAuthUser.uid,
            email: email!,
            password: password!,
          );
        } catch (rollbackError) {
          developer.log(
            'CRITICAL: Servant create and rollback both failed. UID: ${createdAuthUser.uid}',
            error: rollbackError,
            name: 'ProvisionServantWithAuthUseCase',
          );
          rethrow;
        }
      }
      rethrow;
    }
  }

  Future<void> archive({
    required String docId,
    required String performedByUid,
    String? linkedUid,
    String? capturedTeamId,
    List<String>? capturedTeamIds,
  }) async {
    await _servantRepository.deleteServant(
      docId,
      performedByUid: performedByUid,
    );

    if (linkedUid == null || linkedUid.trim().isEmpty) return;

    try {
      await _provisioningService.archiveUser(uid: linkedUid.trim());
    } catch (archiveError) {
      try {
        await _servantRepository.restoreServant(
          docId,
          performedByUid: performedByUid,
          assignedTeamId: capturedTeamId,
          assignedTeamIds: capturedTeamIds,
        );
      } catch (rollbackError) {
        developer.log(
          'CRITICAL: Servant archive and rollback both failed. UID: $linkedUid',
          error: rollbackError,
          name: 'ProvisionServantWithAuthUseCase',
        );
        rethrow;
      }
      rethrow;
    }
  }

  Future<void> restore({
    required String docId,
    required String performedByUid,
    String? linkedUid,
  }) async {
    await _servantRepository.restoreServant(
      docId,
      performedByUid: performedByUid,
    );

    if (linkedUid == null || linkedUid.trim().isEmpty) return;

    try {
      await _provisioningService.restoreUser(uid: linkedUid.trim());
    } catch (restoreError) {
      try {
        await _servantRepository.deleteServant(
          docId,
          performedByUid: performedByUid,
        );
      } catch (rollbackError) {
        developer.log(
          'CRITICAL: Servant restore and rollback both failed. UID: $linkedUid',
          error: rollbackError,
          name: 'ProvisionServantWithAuthUseCase',
        );
        rethrow;
      }
      rethrow;
    }
  }
}

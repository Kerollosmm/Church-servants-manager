import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/admin_user_provisioning_models.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_exceptions.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminAuthUserHandle {
  const AdminAuthUserHandle(this.uid);

  final String uid;
}

abstract class AdminAuthClient {
  Future<AdminAuthUserHandle> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  });

  Future<void> rollbackCreatedUser({required String uid});
}

class FirebaseAdminAuthClient implements AdminAuthClient {
  FirebaseAdminAuthClient({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  HttpsCallable _callable(String name) => _functions.httpsCallable(name);

  Never _mapFunctionsException(FirebaseFunctionsException error) {
    switch (error.code) {
      case 'invalid-argument':
        throw GenericAuthException(
          error.message ?? 'Invalid provisioning input.',
        );
      case 'already-exists':
        throw EmailAlreadyInUseAuthException();
      case 'permission-denied':
        throw const GenericAuthException(
          'You do not have permission to provision users.',
        );
      case 'unauthenticated':
        throw UserNotLoggedInAuthException();
      case 'not-found':
        throw UserNotFoundAuthException();
      default:
        throw GenericAuthException(
          error.message ?? 'Provisioning request failed.',
        );
    }
  }

  @override
  Future<AdminAuthUserHandle> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      final response = await _callable('createPrivilegedUser')
          .call<Map<String, dynamic>>(
            AdminUserProvisioningRequest(
              email: email,
              password: password,
              name: name,
              role: role,
            ).toJson(),
          );

      final body = Map<Object?, Object?>.from(response.data);
      final parsed = AdminUserProvisioningResponse.fromJson(body);
      return AdminAuthUserHandle(parsed.uid);
    } on FirebaseFunctionsException catch (error) {
      _mapFunctionsException(error);
    } on FormatException catch (error) {
      throw GenericAuthException(error.message);
    }
  }

  @override
  Future<void> rollbackCreatedUser({required String uid}) async {
    try {
      await _callable(
        'rollbackPrivilegedUser',
      ).call<Map<String, dynamic>>(AdminUserRollbackRequest(uid: uid).toJson());
    } on FirebaseFunctionsException catch (error) {
      _mapFunctionsException(error);
    }
  }
}

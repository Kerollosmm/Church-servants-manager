import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/auth/data/models/admin_user_provisioning_models.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_exceptions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> archiveUser({required String uid});

  Future<void> restoreUser({required String uid});

  Future<void> changeUserRole({required String uid, required UserRole role});
}

class FirebaseAdminAuthClient implements AdminAuthClient {
  FirebaseAdminAuthClient({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
  }) : _functions = functions ?? FirebaseFunctions.instance,
       _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _db;

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
      // NOTE: User creation for others MUST happen in a trusted environment.
      // On Spark plan without Functions, this will fail.
      // Recommendations:
      // 1. Upgrade to Blaze (pay-as-you-go, but has free tier).
      // 2. Use a local script with Admin SDK for one-off provisioning.
      // 3. Have users self-register and then an admin changes their role.
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
    } catch (e) {
      throw GenericAuthException(
        'Cloud Functions are disabled on Spark Plan. Please use the "Self-Registration + Admin Upgrade" workflow or upgrade to Blaze plan.',
      );
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
    } catch (_) {
      // Best effort deletion from Firestore if function fails
      await _db.collection(FirestoreCollections.users).doc(uid).delete();
    }
  }

  @override
  Future<void> archiveUser({required String uid}) async {
    try {
      // Cost-efficient Spark Plan fix: Update Firestore directly.
      // The authStateChanges listener in the app will detect this and
      // force a sign-out if necessary.
      await _db.collection(FirestoreCollections.users).doc(uid).update({
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw GenericAuthException('Failed to archive user: $e');
    }
  }

  @override
  Future<void> restoreUser({required String uid}) async {
    try {
      // Cost-efficient Spark Plan fix: Update Firestore directly.
      await _db.collection(FirestoreCollections.users).doc(uid).update({
        'isArchived': false,
        'restoredAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw GenericAuthException('Failed to restore user: $e');
    }
  }

  @override
  Future<void> changeUserRole({
    required String uid,
    required UserRole role,
  }) async {
    try {
      // Cost-efficient Spark Plan fix: Update Firestore directly.
      // Firestore rules allow Admins to update the 'role' field of others.
      await _db.collection(FirestoreCollections.users).doc(uid).update({
        'role': role.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw GenericAuthException('Failed to update user role: $e');
    }
  }
}

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_exceptions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  FirebaseAdminAuthClient({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<AdminAuthUserHandle> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      // SPARK PLAN WORKAROUND:
      // Client-side code cannot create other users' Auth accounts.
      // We create an "Invitation" record. The user will self-register,
      // and the app will assign this role upon first login.

      final invitationId = email.trim().toLowerCase();
      await _db
          .collection(FirestoreCollections.invitations)
          .doc(invitationId)
          .set({
            'email': email.trim().toLowerCase(),
            'role': role.name,
            'name': name.trim(),
            'invitedAt': FieldValue.serverTimestamp(),
            'status': 'pending',
          });

      // We return the email as a temporary UID handle
      return AdminAuthUserHandle(invitationId);
    } catch (e) {
      throw GenericAuthException('Failed to create invitation: $e');
    }
  }

  @override
  Future<void> rollbackCreatedUser({required String uid}) async {
    try {
      // Rollback is deleting the invitation
      await _db.collection(FirestoreCollections.invitations).doc(uid).delete();
    } catch (_) {
      // Best effort
    }
  }

  @override
  Future<void> archiveUser({required String uid}) async {
    try {
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
      await _db.collection(FirestoreCollections.users).doc(uid).update({
        'role': role.name,
      });
    } catch (e) {
      throw GenericAuthException('Failed to change user role: $e');
    }
  }
}

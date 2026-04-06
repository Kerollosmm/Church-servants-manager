import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_exceptions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthUserProfileStore {
  AuthUserProfileStore({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<AuthUser> fetchUser(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc;
      try {
        doc = await _db
            .collection(FirestoreCollections.users)
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 12));
      } catch (_) {
        doc = await _db
            .collection(FirestoreCollections.users)
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
      }

      if (!doc.exists || doc.data() == null) {
        throw UserNotFoundAuthException();
      }

      return AuthUser.fromJson(doc.data()!);
    } catch (e) {
      if (e is UserNotFoundAuthException) rethrow;
      throw GenericAuthException('Failed to fetch user data: $e');
    }
  }

  Future<void> saveUser(AuthUser appUser) async {
    try {
      final payload = <String, dynamic>{
        'uid': appUser.uid,
        'name': appUser.name,
        'email': appUser.email,
        'role': appUser.role.name,
        'isEmailVerified': appUser.isEmailVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (appUser.isArchived) {
        payload['isArchived'] = true;
      }
      if (appUser.archivedAt != null) {
        payload['archivedAt'] = appUser.archivedAt;
      }
      if (appUser.archivedByUserId != null &&
          appUser.archivedByUserId!.isNotEmpty) {
        payload['archivedByUserId'] = appUser.archivedByUserId;
      } else {
        payload['archivedByUserId'] = FieldValue.delete();
      }
      if (appUser.archiveReason != null && appUser.archiveReason!.isNotEmpty) {
        payload['archiveReason'] = appUser.archiveReason;
      } else {
        payload['archiveReason'] = FieldValue.delete();
      }
      if (appUser.restoredAt != null) {
        payload['restoredAt'] = appUser.restoredAt;
      } else {
        payload['restoredAt'] = FieldValue.delete();
      }
      if (appUser.restoredByUserId != null &&
          appUser.restoredByUserId!.isNotEmpty) {
        payload['restoredByUserId'] = appUser.restoredByUserId;
      } else {
        payload['restoredByUserId'] = FieldValue.delete();
      }
      if (appUser.restorePendingPasswordReset) {
        payload['restorePendingPasswordReset'] = true;
      }
      if (appUser.groupId != null && appUser.groupId!.isNotEmpty) {
        payload['groupId'] = appUser.groupId;
      }
      if (appUser.assignedTeamIds.isNotEmpty) {
        payload['assignedTeamIds'] = appUser.assignedTeamIds;
      }
      if (appUser.assignedTeamId != null &&
          appUser.assignedTeamId!.isNotEmpty) {
        payload['assignedTeamId'] = appUser.assignedTeamId;
      } else {
        payload['assignedTeamId'] = FieldValue.delete();
      }

      await _db
          .collection(FirestoreCollections.users)
          .doc(appUser.uid)
          .set(payload, SetOptions(merge: true));
    } catch (e) {
      throw GenericAuthException('Failed to save user data: $e');
    }
  }

  Future<void> updateUserFields(String uid, Map<String, dynamic> fields) async {
    try {
      await _db.collection(FirestoreCollections.users).doc(uid).update({
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw GenericAuthException('Failed to update user data: $e');
    }
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection(FirestoreCollections.users).doc(uid).delete();
  }
}

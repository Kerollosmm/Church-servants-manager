import 'dart:developer' as developer;
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

  Future<void> saveUser(AuthUser appUser, {String? initialRole}) async {
    try {
      // DRIVE-01: Stop client-side write-backs of authorization fields.
      // role, isArchived, and team assignments are now exclusively driven
      // by administrative Firestore writes to prevent stale data revert.
      final payload = <String, dynamic>{
        'uid': appUser.uid,
        'name': appUser.name,
        'email': appUser.email,
        'isEmailVerified': appUser.isEmailVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only set role if it's an initial creation (e.g., self-registration)
      if (initialRole != null) {
        // SPARK PLAN FIX: Check if there is an invitation for this user
        try {
          final inviteRef = _db
              .collection(FirestoreCollections.invitations)
              .doc(appUser.email.toLowerCase().trim());

          await _db.runTransaction((transaction) async {
            final inviteDoc = await transaction.get(inviteRef);
            if (inviteDoc.exists) {
              final inviteData = inviteDoc.data();
              if (inviteData != null &&
                  inviteData['status'] != 'claimed' &&
                  inviteData['role'] != null) {
                payload['role'] = inviteData['role'];
                // Mark invitation as claimed
                transaction.update(inviteRef, {
                  'status': 'claimed',
                  'claimedAt': FieldValue.serverTimestamp(),
                  'claimedByUid': appUser.uid,
                });
              } else {
                payload['role'] = initialRole;
              }
            } else {
              payload['role'] = initialRole;
            }
          });
        } catch (e, stack) {
          developer.log(
            'Invitation transaction failed',
            error: e,
            stackTrace: stack,
            name: 'AuthUserProfileStore',
          );
          // Fallback to default initial role if invitation check fails
          payload['role'] = initialRole;
        }
      }

      // These fields are strictly READ-ONLY for the client saveUser operation
      // We only allow updating non-sensitive metadata here.
      if (appUser.restorePendingPasswordReset) {
        payload['restorePendingPasswordReset'] = true;
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

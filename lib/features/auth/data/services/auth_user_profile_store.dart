import 'dart:developer' as developer;
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/auth_user_local_store.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_exceptions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthUserProfileStore {
  AuthUserProfileStore({
    FirebaseFirestore? firestore,
    required AuthUserLocalStore localStore,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _localStore = localStore;

  final FirebaseFirestore _db;
  final AuthUserLocalStore _localStore;

  Future<AuthUser> fetchUser(String uid) async {
    try {
      // Mandate: Check Hive before Firestore
      final cached = _localStore.getUser();
      if (cached != null && cached.uid == uid) {
        return cached;
      }

      // Mandatory Check: One-time get with Source.serverAndCache
      final doc = await _db
          .collection(FirestoreCollections.users)
          .doc(uid)
          .get(const GetOptions());

      if (!doc.exists || doc.data() == null) {
        throw UserNotFoundAuthException();
      }

      final user = AuthUser.fromJson(doc.data()!);
      // Persist to Hive immediately
      await _localStore.saveUser(user);
      return user;
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
      final userRef = _db
          .collection(FirestoreCollections.users)
          .doc(appUser.uid);
      final payload = <String, dynamic>{
        'uid': appUser.uid,
        'name': appUser.name,
        'email': appUser.email,
        'isEmailVerified': appUser.isEmailVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // These fields are strictly READ-ONLY for the client saveUser operation
      // We only allow updating non-sensitive metadata here.
      if (appUser.restorePendingPasswordReset) {
        payload['restorePendingPasswordReset'] = true;
      }

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

            // ATOMIC FIX: Write user document INSIDE the transaction
            // to ensure invitation is only claimed if user doc is created.
            transaction.set(userRef, payload, SetOptions(merge: true));
          });
          return;
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

      await userRef.set(payload, SetOptions(merge: true));
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

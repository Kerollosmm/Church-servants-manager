import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/auth_user_local_store.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_exceptions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Store for managing the extended user profile (roles, assignments)
/// which is authoritative over Firebase Auth custom claims.
class AuthUserProfileStore {
  AuthUserProfileStore({
    required FirebaseFirestore firestore,
    required AuthUserLocalStore localStore,
  }) : _db = firestore,
       _localStore = localStore;

  final FirebaseFirestore _db;
  final AuthUserLocalStore _localStore;

  Future<DocumentSnapshot<Map<String, dynamic>>> _cachedGet(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      final cached = await ref.get(const GetOptions(source: Source.cache));
      if (cached.exists) return cached;
    } catch (_) {}
    return ref.get(const GetOptions(source: Source.server));
  }

  Future<AuthUser> fetchUser(String uid) async {
    try {
      // Mandate: Check Hive before Firestore
      final cached = _localStore.getUser();
      if (cached != null && cached.uid == uid) {
        return cached;
      }

      // Fetch profile with cache-first, server-fallback strategy
      final doc = await _cachedGet(
        _db.collection(FirestoreCollections.servants).doc(uid),
      );

      if (!doc.exists || doc.data() == null) {
        throw UserNotFoundAuthException();
      }

      final profile = AuthUser.fromJson(doc.data()!);
      return profile.copyWith(uid: uid);
    } catch (e, stackTrace) {
      throw GenericAuthException(
        'Failed to fetch user data',
        e is Exception ? e : Exception(e.toString()),
        stackTrace,
      );
    }
  }

  Future<void> updateUserFields(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection(FirestoreCollections.servants).doc(uid).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw GenericAuthException('Failed to update user data: $e');
    }
  }

  Future<void> saveUser(AuthUser user, {String? initialRole}) async {
    try {
      final data = user.toJson();
      if (initialRole != null) {
        data['role'] = initialRole;
      }
      await _db.collection(FirestoreCollections.servants).doc(user.uid).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw GenericAuthException('Failed to save user data: $e');
    }
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection(FirestoreCollections.servants).doc(uid).delete();
  }
}

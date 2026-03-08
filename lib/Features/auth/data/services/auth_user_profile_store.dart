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
      await _db
          .collection(FirestoreCollections.users)
          .doc(appUser.uid)
          .set(payload, SetOptions(merge: true));
    } catch (e) {
      throw GenericAuthException('Failed to save user data: $e');
    }
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection(FirestoreCollections.users).doc(uid).delete();
  }
}

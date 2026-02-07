import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/constants/firestore_collections.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/auth/domain/failures/auth_failures.dart';
import 'package:church_managment_system/features/auth/domain/failures/auth_exceptions.dart';
import 'package:church_managment_system/features/auth/data/services/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuth, FirebaseAuthException;
import 'package:firebase_core/firebase_core.dart';

class FirebaseAuthProvider implements AuthProvider {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  // In-memory cache for user data
  final Map<String, AuthUser> _userCache = {};

  FirebaseAuthProvider({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

  @override
  Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  @override
  AuthUser? get currentUser {
    final user = _auth.currentUser;
    if (user != null) {
      // Check if we have cached data with role info
      if (_userCache.containsKey(user.uid)) {
        return _userCache[user.uid];
      }
      return AuthUser.fromFirebase(user);
    }
    return null;
  }

  @override
  Stream<AuthUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        _userCache.clear();
        return null;
      }
      return await getUserData(user.uid);
    });
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      final user = _auth.currentUser;
      if (user != null) {
        if (!user.emailVerified) {
          throw EmailNotVerifiedAuthException();
        }
        return await getUserData(user.uid);
      } else {
        throw UserNotLoggedInAuthException();
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw UserNotFoundAuthException();
        case 'wrong-password':
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
          throw WrongPasswordAuthException();
        case 'invalid-email':
          throw InvalidEmailAuthException();
        case 'user-disabled':
          throw const GenericAuthException('This account has been disabled');
        default:
          rethrow;
      }
    } on EmailNotVerifiedAuthException {
      rethrow;
    } catch (e) {
      if (e is AuthFailure || e is Exception) {
        rethrow;
      }
      throw GenericAuthException('Login failed: $e');
    }
  }

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
    required String name,
    UserRole role = UserRole.student,
    String? grade,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = _auth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();

        final appUser = AuthUser(
          uid: user.uid,
          name: name,
          email: email,
          role: role,
          isEmailVerified: false,
        );

        await _saveUserToFirestore(appUser);
        _userCache[appUser.uid] = appUser;
        return appUser;
      } else {
        throw UserNotLoggedInAuthException();
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          throw WeakPasswordAuthException();
        case 'email-already-in-use':
          throw EmailAlreadyInUseAuthException();
        case 'invalid-email':
          throw InvalidEmailAuthException();
        default:
          rethrow;
      }
    } catch (e) {
      if (e is WeakPasswordAuthException ||
          e is EmailAlreadyInUseAuthException ||
          e is InvalidEmailAuthException ||
          e is UserNotLoggedInAuthException ||
          e is FirebaseAuthException) {
        rethrow;
      }
      throw GenericAuthException(e.toString());
    }
  }

  @override
  Future<void> logOut() async {
    final user = _auth.currentUser;
    if (user != null) {
      _userCache.remove(user.uid);
      await _auth.signOut();
    } else {
      throw UserNotLoggedInAuthException();
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    } else {
      throw UserNotLoggedInAuthException();
    }
  }

  @override
  Future<void> sendPasswordReset({required String toEmail}) async {
    try {
      await _auth.sendPasswordResetEmail(email: toEmail);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
        case 'firebase_auth/invalid-email':
          throw InvalidEmailAuthException();
        case 'user-not-found':
        case 'firebase_auth/user-not-found':
          throw UserNotFoundAuthException();
        default:
          rethrow;
      }
    } catch (e) {
      if (e is FirebaseAuthException) rethrow;
      throw const PasswordResetAuthException();
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      final verified = user.emailVerified;
      // Update cache
      if (_userCache.containsKey(user.uid)) {
        _userCache[user.uid] = _userCache[user.uid]!.copyWith(
          isEmailVerified: verified,
        );
      }
      return verified;
    }
    return false;
  }

  @override
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      // Invalidate cache to force fetch on next access
      _userCache.remove(user.uid);
    }
  }

  /// Get user data from Firestore
  Future<AuthUser> getUserData(String uid) async {
    // Check cache first
    if (_userCache.containsKey(uid)) {
      return _userCache[uid]!;
    }

    try {
      // Try to fetch from server first to get latest data
      DocumentSnapshot<Map<String, dynamic>> doc;
      try {
        doc = await _db
            .collection(FirestoreCollections.users)
            .doc(uid)
            .get(const GetOptions(source: Source.server));
      } catch (e) {
        // Fallback to cache if server is unavailable
        doc = await _db
            .collection(FirestoreCollections.users)
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
      }

      if (doc.exists) {
        final user = AuthUser.fromJson(doc.data()!);
        _userCache[uid] = user;
        return user;
      } else {
        // Create user record if exists in Auth but not Firestore
        final firebaseUser = _auth.currentUser;
        if (firebaseUser != null) {
          final newUser = AuthUser(
            uid: uid,
            name:
                firebaseUser.displayName ??
                firebaseUser.email?.split('@').first ??
                'User',
            email: firebaseUser.email ?? '',
            role: UserRole.student,
            isEmailVerified: firebaseUser.emailVerified,
          );
          await _saveUserToFirestore(newUser);
          _userCache[uid] = newUser;
          return newUser;
        }
        throw UserNotFoundAuthException();
      }
    } catch (e) {
      if (e is UserNotFoundAuthException) rethrow;
      throw GenericAuthException('Failed to fetch user data: $e');
    }
  }

  Future<void> _saveUserToFirestore(AuthUser appUser) async {
    try {
      await _db
          .collection(FirestoreCollections.users)
          .doc(appUser.uid)
          .set(appUser.toJson());
    } catch (e) {
      throw GenericAuthException('Failed to save user data: $e');
    }
  }
}
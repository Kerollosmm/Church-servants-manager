import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/models/auth_user.dart';
import 'package:church_managment_system/features/auth/data/services/auth_exceptions.dart';
import 'package:church_managment_system/features/auth/data/services/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuth, FirebaseAuthException;
import 'package:firebase_core/firebase_core.dart';

class FirebaseAuthProvider implements AuthProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  @override
  AuthUser? get currentUser {
    final user = _auth.currentUser;
    if (user != null) {
      return AuthUser.fromFirebase(user);
    }
    return null;
  }

  @override
  Stream<AuthUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
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
          throw GenericAuthException(e.message ?? e.code);
      }
    } on EmailNotVerifiedAuthException {
      rethrow;
    } catch (e) {
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
          throw GenericAuthException(e.message ?? e.toString());
      }
    } catch (e) {
      if (e is WeakPasswordAuthException ||
          e is EmailAlreadyInUseAuthException ||
          e is InvalidEmailAuthException ||
          e is UserNotLoggedInAuthException) {
        rethrow;
      }
      throw const GenericAuthException();
    }
  }

  @override
  Future<void> logOut() async {
    final user = _auth.currentUser;
    if (user != null) {
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
          throw PasswordResetAuthException(e.message);
      }
    } catch (_) {
      throw const PasswordResetAuthException();
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }

  @override
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  /// Get user data from Firestore
  Future<AuthUser> getUserData(String uid) async {
    try {
      // Force fetch from server to get latest data
      final doc = await _db
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server));
      if (doc.exists) {
        return AuthUser.fromJson(doc.data()!);
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
      await _db.collection('users').doc(appUser.uid).set(appUser.toJson());
    } catch (e) {
      throw GenericAuthException('Failed to save user data: $e');
    }
  }
}

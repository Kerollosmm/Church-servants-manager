import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csms/Features/auth/domain/failures/auth_failures.dart';
import 'package:csms/core/constants/enums.dart';
import 'package:csms/core/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Singleton AuthService using direct Firebase instances
class AuthService {
  AuthService._();
  static final AuthService _instance = AuthService._();
  factory AuthService.firebase() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Login with email and password
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;

      if (!user.emailVerified) {
        throw const EmailNotVerifiedFailure();
      }

      return await _getUserData(user.uid);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw const UserNotFoundFailure();
        case 'wrong-password':
          throw const WrongPasswordFailure();
        case 'invalid-email':
          throw const InvalidEmailFailure();
        case 'user-disabled':
          throw const GenericAuthFailure(
            'This user account has been disabled.',
          );
        default:
          throw GenericAuthFailure(e.message ?? 'Authentication failed');
      }
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw GenericAuthFailure('Login failed: ${e.toString()}');
    }
  }

  /// Register new user with email verification
  Future<AppUser> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? grade,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;
      await user.sendEmailVerification();

      final appUser = AppUser(
        uid: user.uid,
        name: name,
        email: email,
        role: role,
        grade: grade,
      );

      return await _saveUserToFirestore(appUser);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          throw const WeakPasswordFailure();
        case 'email-already-in-use':
          throw const EmailAlreadyInUseFailure();
        case 'invalid-email':
          throw const InvalidEmailFailure();
        default:
          throw GenericAuthFailure(e.message ?? 'Registration failed');
      }
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw GenericAuthFailure('Registration failed: ${e.toString()}');
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      } else if (user == null) {
        throw const UserNotLoggedInFailure();
      }
    } on FirebaseAuthException catch (e) {
      throw GenericAuthFailure(
        e.message ?? 'Failed to send verification email',
      );
    } catch (e) {
      throw GenericAuthFailure(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw GenericAuthFailure('Logout failed: ${e.toString()}');
    }
  }

  Future<AppUser?> getCurrentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      return await _getUserData(user.uid);
    } catch (e) {
      // If we can't get data, maybe just return null or throw?
      // Retaining null return for now as per original logic pattern
      return null;
    }
  }

  Future<AppUser> _getUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromJson(doc.data()!);
      } else {
        // Fallback creator if user exists in Auth but not Firestore
        final firebaseUser = _auth.currentUser;
        if (firebaseUser != null) {
          final newUser = AppUser(
            uid: uid,
            name:
                firebaseUser.displayName ??
                firebaseUser.email?.split('@').first ??
                'User',
            email: firebaseUser.email ?? '',
            role: UserRole.student,
          );
          return await _saveUserToFirestore(newUser);
        }
        throw const UserNotFoundFailure('User data not found in database');
      }
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw GenericAuthFailure('Failed to fetch user data: ${e.toString()}');
    }
  }

  Future<AppUser> _saveUserToFirestore(AppUser appUser) async {
    try {
      await _db.collection('users').doc(appUser.uid).set(appUser.toJson());
      return appUser;
    } catch (e) {
      throw GenericAuthFailure('Failed to save user data: ${e.toString()}');
    }
  }
}

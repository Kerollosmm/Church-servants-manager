import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csms/core/constants/enums.dart';
import 'package:csms/core/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Custom exception for unverified email
class EmailNotVerifiedException implements Exception {
  final String message;
  EmailNotVerifiedException([this.message = 'Email not verified']);
  @override
  String toString() => message;
}

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
      print('[AuthService] Login success for: ${user.email}');
      print('[AuthService] Email verified: ${user.emailVerified}');

      if (!user.emailVerified) {
        print('[AuthService] Email NOT verified');
        throw EmailNotVerifiedException(
          'Please verify your email before logging in.',
        );
      }

      print('[AuthService] Fetching Firestore data...');
      return await _getUserData(user.uid);
    } on FirebaseAuthException catch (e) {
      print('[AuthService] FirebaseAuthException: $e');
      rethrow;
    } on EmailNotVerifiedException {
      rethrow;
    } catch (e) {
      print('[AuthService] Error: $e');
      throw Exception('Login failed: ${e.toString()}');
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
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<AppUser?> getCurrentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      return await _getUserData(user.uid);
    } catch (e) {
      return null;
    }
  }

  Future<AppUser> _getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromJson(doc.data()!);
    } else {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        print('[AuthService] Creating Firestore document for user');
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
      throw Exception('User not found');
    }
  }

  Future<AppUser> _saveUserToFirestore(AppUser appUser) async {
    await _db.collection('users').doc(appUser.uid).set(appUser.toJson());
    return appUser;
  }
}

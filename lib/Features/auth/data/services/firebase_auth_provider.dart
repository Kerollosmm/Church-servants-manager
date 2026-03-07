import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/constants/firestore_collections.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/auth/domain/failures/auth_failures.dart';
import 'package:church_managment_system/features/auth/domain/failures/auth_exceptions.dart';
import 'package:church_managment_system/features/auth/data/services/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuth, FirebaseAuthException, User;

class FirebaseAuthProvider implements AuthProvider {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  // In-memory cache for user data
  final Map<String, AuthUser> _userCache = {};

  // Cached secondary app for admin account creation (avoids per-call overhead).
  static const _secondaryAppName = 'admin_account_creator';
  FirebaseApp? _secondaryApp;

  FirebaseAuthProvider({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

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
    User? createdFirebaseUser;
    var profileSaved = false;
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = _auth.currentUser;
      createdFirebaseUser = user;
      if (user != null) {
        final appUser = AuthUser(
          uid: user.uid,
          name: name,
          email: email,
          role: role,
          isEmailVerified: false,
        );

        await _saveUserToFirestore(appUser);
        profileSaved = true;
        _userCache[appUser.uid] = appUser;

        try {
          await user.sendEmailVerification();
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              'FirebaseAuthProvider: Initial verification email send failed '
              '(${e.runtimeType})',
            );
          }
        }

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
      if (!profileSaved && createdFirebaseUser != null) {
        final rollbackUid = createdFirebaseUser.uid;
        try {
          await createdFirebaseUser.delete();
          final currentUser = _auth.currentUser;
          if (currentUser != null && currentUser.uid == rollbackUid) {
            await _auth.signOut();
          }
        } catch (rollbackError) {
          _userCache.remove(rollbackUid);
          throw const GenericAuthException(
            'Account setup failed and cleanup was incomplete. Please contact support or try again later.',
          );
        } finally {
          _userCache.remove(rollbackUid);
        }
      }

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

  /// Get user data from Firestore with improved cache/server fallback
  Future<AuthUser> getUserData(String uid, {bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh && _userCache.containsKey(uid)) {
      return _userCache[uid]!;
    }

    try {
      // Use default source first to allow Firestore to serve from local cache
      // when available, then fall back to explicit cache on failures.
      DocumentSnapshot<Map<String, dynamic>> doc;
      try {
        doc = await _db
            .collection(FirestoreCollections.users)
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 12));
      } catch (e) {
        doc = await _db
            .collection(FirestoreCollections.users)
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
      }

      if (doc.exists && doc.data() != null) {
        final user = AuthUser.fromJson(doc.data()!);
        _userCache[uid] = user;
        return user;
      } else {
        throw UserNotFoundAuthException();
      }
    } catch (e) {
      if (e is UserNotFoundAuthException) rethrow;
      throw GenericAuthException('Failed to fetch user data: $e');
    }
  }

  Future<void> _saveUserToFirestore(AuthUser appUser) async {
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

  /// Returns the cached secondary FirebaseApp, creating it once if needed.
  Future<FirebaseApp> _getOrCreateSecondaryApp() async {
    if (_secondaryApp != null) {
      // Verify the cached reference is still valid.
      try {
        Firebase.app(_secondaryAppName);
        return _secondaryApp!;
      } catch (_) {
        _secondaryApp = null;
      }
    }
    _secondaryApp = await Firebase.initializeApp(
      name: _secondaryAppName,
      options: Firebase.app().options,
    );
    return _secondaryApp!;
  }

  Future<void> _deleteUserDocument(String uid) async {
    _userCache.remove(uid);
    await _db.collection(FirestoreCollections.users).doc(uid).delete();
  }

  @override
  Future<AuthUser> createUserAsAdmin({
    required String email,
    required String password,
    required String name,
    UserRole role = UserRole.student,
  }) async {
    User? createdFirebaseUser;
    var profileSaved = false;
    FirebaseAuth? secondaryAuth;
    try {
      final secondaryApp = await _getOrCreateSecondaryApp();
      secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUser = credential.user;
      createdFirebaseUser = newUser;
      if (newUser == null) {
        throw const GenericAuthException('Account creation returned no user.');
      }

      final appUser = AuthUser(
        uid: newUser.uid,
        name: name,
        email: email,
        role: role,
        isEmailVerified: false,
      );

      await _saveUserToFirestore(appUser);
      profileSaved = true;

      try {
        await newUser.sendEmailVerification();
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            'FirebaseAuthProvider: Verification email send failed '
            '(${e.runtimeType})',
          );
        }
      }

      await secondaryAuth.signOut();

      return appUser;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          throw WeakPasswordAuthException();
        case 'email-already-in-use':
          throw EmailAlreadyInUseAuthException();
        case 'invalid-email':
          throw InvalidEmailAuthException();
        default:
          throw GenericAuthException('Account creation failed: ${e.message}');
      }
    } catch (e) {
      if (!profileSaved && createdFirebaseUser != null) {
        final rollbackUid = createdFirebaseUser.uid;
        try {
          await createdFirebaseUser.delete();
        } catch (_) {
          throw const GenericAuthException(
            'Account setup failed and cleanup was incomplete. Please contact support or try again later.',
          );
        } finally {
          _userCache.remove(rollbackUid);
          try {
            await secondaryAuth?.signOut();
          } catch (_) {}
        }
      }
      if (e is AuthFailure) rethrow;
      throw GenericAuthException('Account creation failed: $e');
    }
  }

  Future<void> rollbackAdminCreatedUser({
    required String uid,
    required String email,
    required String password,
  }) async {
    FirebaseAuth? secondaryAuth;
    var authDeleted = false;

    try {
      final secondaryApp = await _getOrCreateSecondaryApp();
      secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final credential = await secondaryAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const GenericAuthException('Rollback failed: user not found.');
      }

      if (user.uid != uid) {
        throw const GenericAuthException(
          'Rollback failed: created account does not match expected user.',
        );
      }

      await user.delete();
      authDeleted = true;
      await _deleteUserDocument(uid);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        authDeleted = true;
        await _deleteUserDocument(uid);
        return;
      }
      throw GenericAuthException('Rollback failed: ${e.message}');
    } catch (e) {
      if (authDeleted) {
        try {
          await _deleteUserDocument(uid);
        } catch (_) {
          throw const GenericAuthException(
            'Rollback removed the auth account but failed to remove the user profile. Please clean up the profile manually.',
          );
        }
      }

      if (e is AuthFailure) rethrow;
      throw GenericAuthException('Rollback failed: $e');
    } finally {
      try {
        await secondaryAuth?.signOut();
      } catch (_) {}
    }
  }
}

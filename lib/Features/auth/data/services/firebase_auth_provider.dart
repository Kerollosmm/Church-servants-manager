import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/auth_user_profile_store.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_failures.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_exceptions.dart';
import 'package:church_management_system/features/auth/data/services/auth_provider.dart';
import 'package:flutter/foundation.dart';

import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuth, FirebaseAuthException, User;

class FirebaseAuthProvider implements AuthProvider {
  final FirebaseAuth _auth;
  final AuthUserProfileStore _userProfileStore;

  // In-memory cache for user data
  final Map<String, AuthUser> _userCache = {};

  FirebaseAuthProvider({
    FirebaseAuth? auth,
    AuthUserProfileStore? userProfileStore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _userProfileStore = userProfileStore ?? AuthUserProfileStore();

  @override
  AuthUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _userCache[user.uid] ?? AuthUser.fromFirebase(user);
  }

  @override
  Stream<AuthUser?> get authStateChanges {
    return _auth.idTokenChanges().asyncMap((user) async {
      if (user == null) {
        _userCache.clear();
        return null;
      }
      return await getUserData(user.uid);
    });
  }

  Future<AuthUser> _clearRestorePendingPasswordResetIfNeeded(
    AuthUser user,
  ) async {
    if (!user.restorePendingPasswordReset) {
      return user;
    }

    final updatedUser = user.copyWith(restorePendingPasswordReset: false);
    _userCache[updatedUser.uid] = updatedUser;
    return updatedUser;
  }

  Future<void> _signOutSilently(String uid) async {
    _userCache.remove(uid);
    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.uid == uid) {
      await _auth.signOut();
    }
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
          await _signOutSilently(user.uid);
          throw EmailNotVerifiedAuthException();
        }

        var appUser = await getUserData(user.uid, forceRefresh: true);
        if (appUser.isArchived) {
          await _signOutSilently(user.uid);
          throw const ArchivedAccountAuthException(
            'تمت أرشفة هذا الحساب. تواصل مع الإدارة.',
          );
        }

        appUser = await _clearRestorePendingPasswordResetIfNeeded(appUser);
        return appUser;
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
        const effectiveRole = UserRole.student;
        final appUser = AuthUser(
          uid: user.uid,
          name: name,
          email: email,
          role: effectiveRole,
          isEmailVerified: false,
        );

        await _userProfileStore.saveUser(appUser);
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

  User _requireCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) throw UserNotLoggedInAuthException();
    return user;
  }

  @override
  Future<void> logOut() async {
    // FIX [004-H4]: idempotent — no-op when already signed out.
    final user = _auth.currentUser;
    if (user != null) {
      _userCache.remove(user.uid);
      await _auth.signOut();
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    await _requireCurrentUser().sendEmailVerification();
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
    } catch (_) {
      throw const PasswordResetAuthException();
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final verified = user.emailVerified;
    if (_userCache.containsKey(user.uid)) {
      _userCache[user.uid] = _userCache[user.uid]!.copyWith(
        isEmailVerified: verified,
      );
    }
    return verified;
  }

  @override
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      _userCache.remove(user.uid);
    }
  }

  Future<AuthUser> getUserData(String uid, {bool forceRefresh = false}) async {
    if (!forceRefresh && _userCache.containsKey(uid)) {
      return _userCache[uid]!;
    }

    try {
      // Use default source first to allow Firestore to serve from local cache
      // when available, then fall back to explicit cache on failures.
      final user = await _userProfileStore.fetchUser(uid);
      final firebaseUser = _auth.currentUser;
      final syncedUser = firebaseUser != null && firebaseUser.uid == uid
          ? user.copyWith(
              email: firebaseUser.email ?? user.email,
              name: firebaseUser.displayName?.trim().isNotEmpty == true
                  ? firebaseUser.displayName!.trim()
                  : user.name,
              isEmailVerified: firebaseUser.emailVerified,
            )
          : user;

      final resolvedUser = await _clearRestorePendingPasswordResetIfNeeded(
        syncedUser,
      );

      _userCache[uid] = resolvedUser;
      return resolvedUser;
    } catch (e) {
      if (e is UserNotFoundAuthException) rethrow;
      throw GenericAuthException('Failed to fetch user data: $e');
    }
  }
}

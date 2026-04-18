import 'dart:developer' as developer;
import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/auth_provider.dart';
import 'package:church_management_system/features/auth/data/services/auth_user_profile_store.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_exceptions.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_failures.dart';
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
    return _auth.userChanges().asyncMap((user) async {
      if (user == null) {
        _userCache.clear();
        return null;
      }
      
      try {
        final idTokenResult = await user.getIdTokenResult(false);
        final appUser = AuthUser.fromFirebaseToken(user, idTokenResult.claims ?? {});
        _userCache[user.uid] = appUser;
        return appUser;
      } catch (_) {
        // Fallback or handle error
        return AuthUser.fromFirebase(user);
      }
    });
  }

  Future<void> forceTokenRefresh() async {
    await _auth.currentUser?.getIdToken(true);
  }

  Future<AuthUser> _clearRestorePendingPasswordResetIfNeeded(
    AuthUser user,
  ) async {
    if (!user.restorePendingPasswordReset) {
      return user;
    }

    final updatedUser = user.copyWith(restorePendingPasswordReset: false);
    await _userProfileStore.updateUserFields(user.uid, {
      'restorePendingPasswordReset': false,
    });
    _userCache[updatedUser.uid] = updatedUser;
    return updatedUser;
  }

  Future<void> _signOutSilently(String uid) async {
    _userCache.remove(uid);
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return;
    }
    if (currentUser.uid == uid) {
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
        final appUser = AuthUser(
          uid: user.uid,
          name: name,
          email: email,
          role: role,
        );

        await _userProfileStore.saveUser(appUser);
        profileSaved = true;
        _userCache[appUser.uid] = appUser;

        try {
          await user.sendEmailVerification();
        } catch (e) {
          developer.log(
            'Initial verification email send failed',
            error: e,
            name: 'FirebaseAuthProvider',
          );
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
    }
    // Idempotent: no-op if already logged out
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

  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw UserNotLoggedInAuthException();
    }
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'requires-recent-login':
          throw RequiresRecentLoginAuthException();
        case 'weak-password':
          throw WeakPasswordAuthException();
        default:
          throw GenericAuthException('Password update failed: ${e.message}');
      }
    } catch (e) {
      throw GenericAuthException('Password update failed: $e');
    }
  }

  Future<void> clearRestorePendingPasswordReset(String uid) async {
    await _userProfileStore.updateUserFields(uid, {
      'restorePendingPasswordReset': false,
    });
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
      final user = await _userProfileStore.fetchUser(uid);
      final firebaseUser = _auth.currentUser;
      
      var syncedUser = user;
      if (firebaseUser != null && firebaseUser.uid == uid) {
        try {
          final idTokenResult = await firebaseUser.getIdTokenResult(forceRefresh);
          final claims = idTokenResult.claims ?? {};
          final roleString = claims['role'] as String? ?? 'student';
          final role = UserRole.values.firstWhere(
            (e) => e.name == roleString,
            orElse: () => UserRole.student,
          );
          final teamIds = claims['assignedTeamIds'] != null ? List<String>.from(claims['assignedTeamIds']) : <String>[];

          syncedUser = user.copyWith(
            email: firebaseUser.email ?? user.email,
            name: firebaseUser.displayName?.trim().isNotEmpty == true
                ? firebaseUser.displayName!.trim()
                : user.name,
            isEmailVerified: firebaseUser.emailVerified,
            role: role,
            isArchived: claims['isArchived'] ?? user.isArchived,
            assignedTeamIds: teamIds,
            assignedTeamId: claims['assignedTeamId'] ?? user.assignedTeamId,
            groupId: claims['groupId'] ?? user.groupId,
          );
        } catch (_) {
          syncedUser = user.copyWith(
            email: firebaseUser.email ?? user.email,
            name: firebaseUser.displayName?.trim().isNotEmpty == true
                ? firebaseUser.displayName!.trim()
                : user.name,
            isEmailVerified: firebaseUser.emailVerified,
          );
        }
      }

      if (syncedUser != user) {
        await _userProfileStore.saveUser(syncedUser);
      }

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

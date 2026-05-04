import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/auth_user_local_store.dart';
import 'package:church_management_system/features/auth/data/services/auth_user_profile_store.dart';
import 'package:church_management_system/features/auth/data/services/firebase_identity_provider.dart';
import 'package:church_management_system/features/auth/data/utils/auth_error_mapper.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_exceptions.dart';
import 'package:church_management_system/features/auth/domain/repos/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseIdentityProvider _identityProvider;
  final AuthUserProfileStore _userProfileStore;
  final AuthUserLocalStore _localAuthStore;

  AuthUser? _lastKnownAppUser;

  FirebaseAuthRepository({
    required FirebaseIdentityProvider identityProvider,
    required AuthUserProfileStore userProfileStore,
    required AuthUserLocalStore localAuthStore,
    Connectivity?
    connectivity, // Kept for constructor compatibility if injected elsewhere
  }) : _identityProvider = identityProvider,
       _userProfileStore = userProfileStore,
       _localAuthStore = localAuthStore;

  @override
  AuthUser? get currentUser {
    final user = _identityProvider.currentUser;
    if (user == null) return null;
    if (_lastKnownAppUser != null && _lastKnownAppUser!.uid == user.uid) {
      return _lastKnownAppUser;
    }
    return null;
  }

  @override
  Stream<AuthUser?> get userStream {
    return _identityProvider.idTokenChanges.asyncMap((claims) async {
      final firebaseUser = _identityProvider.currentUser;
      if (firebaseUser == null) {
        _lastKnownAppUser = null;
        return null;
      }

      try {
        // Single fetch using serverAndCache
        final profile = await _userProfileStore.fetchUser(firebaseUser.uid);

        final mergedUser = profile.copyWith(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? profile.email,
          name: firebaseUser.displayName?.trim().isNotEmpty == true
              ? firebaseUser.displayName!.trim()
              : profile.name,
          isEmailVerified: firebaseUser.emailVerified,
          // We rely exclusively on the Firestore profile for the role
          role: profile.role,
          isArchived: profile.isArchived,
          assignedTeamIds: profile.assignedTeamIds,
        );

        _lastKnownAppUser = mergedUser;
        return mergedUser;
      } catch (e, s) {
        developer.log(
          'Error fetching user profile stream',
          error: e,
          stackTrace: s,
          name: 'FirebaseAuthRepository',
        );
        // If offline and cache is empty, we throw or return last known
        if (_lastKnownAppUser != null) {
          return _lastKnownAppUser;
        }
        return null; // Signals unauthenticated/error to BLoC
      }
    });
  }

  @override
  Future<void> forceRoleRefresh() async {
    final user = _identityProvider.currentUser;
    if (user != null) {
      await user.getIdToken(true);
    }
  }

  @override
  Future<AuthUser?> getCurrentUser() async => getCurrentAppUser();

  @override
  Future<AuthUser?> getCurrentAppUser({bool forceRefresh = false}) async {
    try {
      final firebaseUser = _identityProvider.currentUser;
      if (firebaseUser == null) {
        _lastKnownAppUser = null;
        return null;
      }

      // Fetch profile using serverAndCache natively (which now includes Hive check)
      final profile = await _userProfileStore.fetchUser(firebaseUser.uid);

      final mergedUser = profile.copyWith(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? profile.email,
        name: firebaseUser.displayName?.trim().isNotEmpty == true
            ? firebaseUser.displayName!.trim()
            : profile.name,
        isEmailVerified: firebaseUser.emailVerified,
        role: profile.role,
        isArchived: profile.isArchived,
        assignedTeamIds: profile.assignedTeamIds,
      );

      _lastKnownAppUser = mergedUser;
      return mergedUser;
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  @override
  AuthUser? get lastKnownAppUser => _lastKnownAppUser;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _identityProvider.signIn(
        email: email,
        password: password,
      );

      if (!user.emailVerified) {
        await _identityProvider.signOut();
        throw EmailNotVerifiedAuthException();
      }

      final appUser = await getCurrentAppUser(forceRefresh: true);
      if (appUser == null) {
        throw UserNotLoggedInAuthException();
      }

      if (appUser.isArchived) {
        await _identityProvider.signOut();
        throw const ArchivedAccountAuthException(
          'تمت أرشفة هذا الحساب. تواصل مع الإدارة.',
        );
      }

      return appUser;
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String name,
    String? grade,
  }) async {
    bool profileSaved = false;
    try {
      final user = await _identityProvider.createUser(
        email: email,
        password: password,
      );

      final appUser = AuthUser(
        uid: user.uid,
        name: name,
        email: email,
        role: UserRole.student,
      );

      await _userProfileStore.saveUser(
        appUser,
        initialRole: UserRole.student.name,
      );
      profileSaved = true;

      try {
        await _identityProvider.sendEmailVerification();
      } catch (_) {
        // Log or handle initial verification email failure if needed
      }

      return appUser;
    } catch (e) {
      if (!profileSaved) {
        final currentUser = _identityProvider.currentUser;
        if (currentUser != null && currentUser.email == email) {
          try {
            await currentUser.delete();
          } catch (_) {
            throw const GenericAuthException(
              'Account setup failed and cleanup was incomplete. Please contact support or try again later.',
            );
          }
        }
      }

      if (e is WeakPasswordAuthException ||
          e is EmailAlreadyInUseAuthException ||
          e is InvalidEmailAuthException ||
          e is UserNotLoggedInAuthException ||
          e is GenericAuthException) {
        rethrow;
      }
      throw AuthErrorMapper.mapException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _identityProvider.signOut();
      _lastKnownAppUser = null;
      // Mandate: Clear local cache on sign out
      await _localAuthStore.deleteUser();
      await FirebaseFirestore.instance.clearPersistence();
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      await _identityProvider.sendEmailVerification();
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _identityProvider.sendPasswordReset(toEmail: email);
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  Future<bool> isEmailVerified() async {
    try {
      return await _identityProvider.isEmailVerified();
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  @override
  Future<void> reloadUser() async {
    try {
      await _identityProvider.reloadUser();
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  @override
  Future<AuthUser?> refreshCurrentAppUser() async {
    try {
      await _identityProvider.forceTokenRefresh();
      await _identityProvider.reloadUser();
      return getCurrentAppUser(forceRefresh: true);
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _identityProvider.updatePassword(newPassword);
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  @override
  Future<void> clearRestorePendingPasswordReset(String uid) async {
    final currentUid = currentUser?.uid;
    if (currentUid == null || currentUid != uid) {
      throw const GenericAuthException(
        'تحذير أمني: لا تملك صلاحية تعديل هذا الحساب.',
      );
    }
    try {
      await _userProfileStore.updateUserFields(uid, {
        'restorePendingPasswordReset': false,
      });
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }
}

import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/auth_user_profile_store.dart';
import 'package:church_management_system/features/auth/data/services/firebase_identity_provider.dart';
import 'package:church_management_system/features/auth/data/services/firestore_profile_provider.dart';
import 'package:church_management_system/features/auth/data/utils/auth_error_mapper.dart';
import 'package:church_management_system/features/auth/domain/auth_freshness_policy.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_exceptions.dart';
import 'package:church_management_system/features/auth/domain/repos/auth_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' show IdTokenResult;
import 'package:rxdart/rxdart.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseIdentityProvider _identityProvider;
  final FirestoreProfileProvider _profileProvider;
  final AuthUserProfileStore _userProfileStore;
  final AuthFreshnessPolicy _freshnessPolicy;
  final Connectivity _connectivity;

  AuthUser? _lastKnownAppUser;
  DateTime? _lastForcedRefreshTime;

  FirebaseAuthRepository({
    required FirebaseIdentityProvider identityProvider,
    required FirestoreProfileProvider profileProvider,
    required AuthUserProfileStore userProfileStore,
    required AuthFreshnessPolicy freshnessPolicy,
    Connectivity? connectivity,
  }) : _identityProvider = identityProvider,
       _profileProvider = profileProvider,
       _userProfileStore = userProfileStore,
       _freshnessPolicy = freshnessPolicy,
       _connectivity = connectivity ?? Connectivity();

  @override
  AuthUser? get currentUser {
    final user = _identityProvider.currentUser;
    if (user == null) return null;
    // Return the last known user if it matches the current UID,
    // as it contains resolved claims.
    if (_lastKnownAppUser != null && _lastKnownAppUser!.uid == user.uid) {
      return _lastKnownAppUser;
    }
    // DO NOT fallback to AuthUser.fromFirebaseUnsafe(user) as it lacks claims.
    // Return null to signal that the full app user is not yet resolved.
    return null;
  }

  @override
  Stream<AuthUser?> get userStream {
    return _identityProvider.authStateChanges.switchMap((firebaseUser) {
      if (firebaseUser == null) {
        _lastKnownAppUser = null;
        _profileProvider.clearAllCache();
        return Stream.value(null);
      }

      // Combine Firebase identity changes with Firestore profile updates
      return Rx.combineLatest2<Map<String, dynamic>, AuthUser?, AuthUser?>(
        _identityProvider.idTokenChanges,
        _profileProvider.watchProfile(firebaseUser.uid),
        (claims, profile) {
          try {
            // Resolve role from token (SSOT for permissions)
            final tokenUser = AuthUser.fromFirebaseToken(firebaseUser, claims);

            if (profile == null) {
              _lastKnownAppUser = tokenUser;
              return tokenUser;
            }

            // Reactive Token Refresh logic:
            if (profile.requiresTokenRefresh) {
              _handleForcedRefresh(firebaseUser.uid);
            }

            // Merge profile data while keeping tokenUser as authority for roles/archive status
            final mergedUser = profile.copyWith(
              uid: tokenUser.uid,
              email: tokenUser.email,
              role: tokenUser.role, // Claims are authority
              isEmailVerified: tokenUser.isEmailVerified,
              isArchived: tokenUser.isArchived, // Claims are authority
              assignedTeamIds:
                  tokenUser.assignedTeamIds, // Claims are authority
              name: firebaseUser.displayName?.trim().isNotEmpty == true
                  ? firebaseUser.displayName!.trim()
                  : profile.name,
            );

            _lastKnownAppUser = mergedUser;
            return mergedUser;
          } catch (e, s) {
            developer.log(
              'Error merging auth stream data',
              error: e,
              stackTrace: s,
              name: 'FirebaseAuthRepository',
            );
            // Return last known good state or tokenUser as fallback
            return _lastKnownAppUser;
          }
        },
      ).distinct();
    });
  }

  bool _isRefreshing = false;
  Future<void> _handleForcedRefresh(String uid) async {
    if (_isRefreshing) return;

    // SPARK PLAN HARDENING: 1-minute debounce for forced refreshes.
    // Prevents redundant Auth/Firestore calls if the watch stream triggers
    // multiple times before the 'requiresTokenRefresh' flag is cleared server-side.
    final now = DateTime.now();
    if (_lastForcedRefreshTime != null &&
        now.difference(_lastForcedRefreshTime!) < const Duration(minutes: 1)) {
      return;
    }

    _isRefreshing = true;
    _lastForcedRefreshTime = now;

    try {
      await _identityProvider.forceTokenRefresh();
      // FIX: Added missing _userProfileStore prefix to correct bug
      await _userProfileStore.updateUserFields(uid, {
        'requiresTokenRefresh': false,
      });
    } finally {
      _isRefreshing = false;
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

      // Offline Session Restore logic
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOffline = connectivityResult.contains(ConnectivityResult.none);

      if (isOffline) {
        if (!_freshnessPolicy.canPerformWrites) {
          // Policy is invalid, and we are offline. Block access.
          return null; // Returning null will trigger AuthUnauthenticated
        }
      }

      // Fetch claims and profile in parallel
      final results = await Future.wait([
        firebaseUser.getIdTokenResult(forceRefresh),
        _profileProvider.getProfile(
          firebaseUser.uid,
          forceRefresh: forceRefresh,
        ),
      ]);

      final tokenResult = results[0] as IdTokenResult;
      final profile = results[1] as AuthUser;

      final tokenUser = AuthUser.fromFirebaseToken(
        firebaseUser,
        tokenResult.claims ?? {},
      );

      final mergedUser = profile.copyWith(
        uid: tokenUser.uid,
        email: tokenUser.email,
        role: tokenUser.role, // Authority
        isEmailVerified: tokenUser.isEmailVerified,
        isArchived: tokenUser.isArchived, // Authority
        assignedTeamIds: tokenUser.assignedTeamIds, // Authority
        name: firebaseUser.displayName?.trim().isNotEmpty == true
            ? firebaseUser.displayName!.trim()
            : profile.name,
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
      await _freshnessPolicy.reset();
      _profileProvider.clearAllCache();
      _lastKnownAppUser = null;
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

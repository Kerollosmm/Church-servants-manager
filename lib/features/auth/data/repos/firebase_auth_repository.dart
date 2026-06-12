import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
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
  final FirebaseFirestore _firestore;

  AuthUser? _lastKnownAppUser;

  FirebaseAuthRepository({
    required FirebaseIdentityProvider identityProvider,
    required AuthUserProfileStore userProfileStore,
    required AuthUserLocalStore localAuthStore,
    required FirebaseFirestore firestore,
    Connectivity?
    connectivity, // Kept for constructor compatibility if injected elsewhere
  }) : _identityProvider = identityProvider,
       _userProfileStore = userProfileStore,
       _localAuthStore = localAuthStore,
       _firestore = firestore;

  @override
  AuthUser? get currentUser {
    final user = _identityProvider.currentUser;
    if (user == null) return null;
    if (_lastKnownAppUser != null && _lastKnownAppUser!.uid == user.uid) {
      return _lastKnownAppUser;
    }
    // Attempt local cache load immediately if memory cache misses
    final localCached = _localAuthStore.getUser();
    if (localCached != null && localCached.uid == user.uid) {
      _lastKnownAppUser = localCached;
      return localCached;
    }
    return null;
  }

  @override
  Stream<AuthUser?> get userStream {
    // Listen for auth state changes natively, ignoring custom claims entirely
    return _identityProvider.idTokenChanges.asyncMap((_) async {
      final firebaseUser = _identityProvider.currentUser;
      if (firebaseUser == null) {
        _lastKnownAppUser = null;
        await _localAuthStore.deleteUser();
        return null;
      }

      try {
        final docRef = _firestore
            .collection(FirestoreCollections.servants)
            .doc(firebaseUser.uid);
        final docSnap = await docRef.get(const GetOptions());

        if (!docSnap.exists || docSnap.data() == null) {
          throw UserNotFoundAuthException();
        }

        final profile = AuthUserModel.fromJson(docSnap.data()!).toDomain();

        final mergedUser = profile.copyWith(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? profile.email,
          name: firebaseUser.displayName?.trim().isNotEmpty == true
              ? firebaseUser.displayName!.trim()
              : profile.name,
          isEmailVerified: firebaseUser.emailVerified,
          // Use profile source of truth for Role & RBAC
          role: profile.role,
          isArchived: profile.isArchived,
          assignedTeamIds: profile.assignedTeamIds,
        );

        _lastKnownAppUser = mergedUser;
        // Save the newly synced user configuration in local persistent storage (cache the resulting role in Hive)
        await _localAuthStore.saveUser(mergedUser);
        return mergedUser;
      } catch (e) {
        developer.log(
          'Failed to hydrate user profile stream',
          name: 'FirebaseAuthRepository',
        );
        // Fallback: If offline and the network fails unexpectedly, return the latest cached state
        if (_lastKnownAppUser != null) {
          return _lastKnownAppUser;
        }
        final cachedUser = _localAuthStore.getUser();
        if (cachedUser != null) {
          _lastKnownAppUser = cachedUser;
          return cachedUser;
        }
        return null;
      }
    });
  }

  @override
  Future<void> forceRoleRefresh() async {
    try {
      await _identityProvider.forceTokenRefresh().timeout(
        const Duration(seconds: 10),
      );
      await _identityProvider.reloadUser().timeout(const Duration(seconds: 10));
    } on TimeoutException catch (_) {
      developer.log(
        'Force role refresh timed out',
        name: 'FirebaseAuthRepository',
      );
    } catch (e) {
      developer.log(
        'Failed to force role refresh',
        error: e,
        name: 'FirebaseAuthRepository',
      );
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
        await _localAuthStore.deleteUser();
        return null;
      }

      // Fetch profile with cache-first fallback
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
      await _localAuthStore.saveUser(mergedUser);
      return mergedUser;
    } catch (e) {
      // In offline scenarios where no user profile is available yet
      final cachedUser = _localAuthStore.getUser();
      if (cachedUser != null) {
        _lastKnownAppUser = cachedUser;
        return cachedUser;
      }
      throw AuthErrorMapper.mapException(e);
    }
  }

  @override
  AuthUser? get lastKnownAppUser =>
      _lastKnownAppUser ?? _localAuthStore.getUser();

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
      await _identityProvider.forceTokenRefresh().timeout(
        const Duration(seconds: 10),
      );
      await _identityProvider.reloadUser().timeout(const Duration(seconds: 10));
      return getCurrentAppUser(forceRefresh: true);
    } on TimeoutException catch (_) {
      developer.log(
        'Auth reload timed out after 10s — returning cached user',
        name: 'FirebaseAuthRepository',
      );
      return lastKnownAppUser;
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

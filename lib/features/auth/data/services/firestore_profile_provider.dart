import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/auth_user_profile_store.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreProfileProvider {
  final FirebaseFirestore _db;
  final AuthUserProfileStore _store;
  final Duration _ttl;

  // Track the last successful remote fetch time for each uid
  final Map<String, DateTime> _lastFetchedAt = {};

  FirestoreProfileProvider({
    FirebaseFirestore? firestore,
    required AuthUserProfileStore store,
    Duration? ttl,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _store = store,
       _ttl = ttl ?? const Duration(hours: 1);

  /// Streams the profile updates from Firestore.
  Stream<AuthUser?> watchProfile(String uid) {
    return _db.collection(FirestoreCollections.users).doc(uid).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        try {
          return AuthUser.fromJson(snapshot.data()!);
        } catch (e) {
          developer.log(
            'Error parsing user profile from Firestore',
            error: e,
            name: 'FirestoreProfileProvider',
          );
          return null;
        }
      }
      return null;
    });
  }

  /// Fetches a profile, using TTL to decide between cache and network,
  /// unless `forceRefresh` is requested.
  Future<AuthUser> getProfile(String uid, {bool forceRefresh = false}) async {
    final now = DateTime.now();
    final lastFetch = _lastFetchedAt[uid];

    final isStale = lastFetch == null || now.difference(lastFetch) > _ttl;
    final shouldFetchRemote = forceRefresh || isStale;

    try {
      final user = await _store.fetchUser(
        uid,
        sourceCacheOnly: !shouldFetchRemote,
      );
      if (shouldFetchRemote) {
        _lastFetchedAt[uid] = now;
      }
      return user;
    } catch (e) {
      if (shouldFetchRemote && lastFetch != null) {
        // Fallback to cache if remote fetch failed but we have a valid past fetch
        developer.log(
          'Remote fetch failed, falling back to cache',
          error: e,
          name: 'FirestoreProfileProvider',
        );
        return await _store.fetchUser(uid, sourceCacheOnly: true);
      }
      rethrow;
    }
  }

  void invalidateCache(String uid) {
    _lastFetchedAt.remove(uid);
  }

  void clearAllCache() {
    _lastFetchedAt.clear();
  }
}

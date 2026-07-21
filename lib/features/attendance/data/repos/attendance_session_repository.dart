import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/core/constants/sync_action_type.dart';
import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/cache_tracker.dart';
import 'package:church_management_system/core/services/sync_service.dart';
import 'package:church_management_system/features/attendance/data/local/attendance_session_local_datasource.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AttendanceSessionRepository {
  AttendanceSessionRepository({
    required FirebaseFirestore firestore,
    required SyncService Function() syncServiceGetter,
    AttendanceSessionLocalDatasource? localDatasource,
  }) : _firestore = firestore,
       _syncServiceGetter = syncServiceGetter,
       _localDatasource = localDatasource ?? AttendanceSessionLocalDatasource();

  final FirebaseFirestore _firestore;
  final SyncService Function() _syncServiceGetter;
  final AttendanceSessionLocalDatasource _localDatasource;

  CollectionReference<Map<String, dynamic>> get _sessionsCol =>
      _firestore.collection(FirestoreCollections.attendance);

  DocumentReference<Map<String, dynamic>> _sessionDoc(
    String teamId,
    String sessionId,
  ) => _sessionsCol.doc(sessionId);

  Future<DocumentSnapshot<Map<String, dynamic>>> _cachedGet(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      final cached = await ref.get(const GetOptions(source: Source.cache));
      if (cached.exists) return cached;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to read from cache inside _cachedGet',
        name: 'AttendanceSessionRepository',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return ref.get(const GetOptions(source: Source.server));
  }

  List<AttendanceSession> _mapSessionsSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final sessions = <AttendanceSession>[];
    for (final doc in snapshot.docs) {
      try {
        sessions.add(
          AttendanceSessionModel.fromMap(doc.data(), doc.id).toDomain(),
        );
      } catch (error) {
        developer.log(
          'skipped malformed attendance session ${doc.reference.path}',
          error: error,
          name: 'AttendanceSessionRepository',
        );
      }
    }
    sessions.sort((first, second) => second.startsAt.compareTo(first.startsAt));
    return sessions;
  }

  Future<List<AttendanceSession>> getActiveSessions(String teamId) async {
    final cached = await _localDatasource.getCachedActiveSessions(teamId);
    if (cached.isNotEmpty) {
      final cacheKey = 'active_sessions_$teamId';
      if (CacheTracker.shouldRevalidate(cacheKey)) {
        unawaited(
          _sessionsCol
              .where('teamId', isEqualTo: teamId)
              .where('isClosed', isEqualTo: false)
              .get(const GetOptions(source: Source.server))
              .catchError(
                (_) => _sessionsCol
                    .where('teamId', isEqualTo: teamId)
                    .where('isClosed', isEqualTo: false)
                    .get(const GetOptions(source: Source.cache)),
              )
              .then((snapshot) {
                final sessions = _mapSessionsSnapshot(snapshot);
                if (sessions.isNotEmpty) {
                  _localDatasource.cacheSessions(sessions);
                  CacheTracker.markFetched(cacheKey);
                }
              })
              .catchError((e) {
                developer.log(
                  'Background revalidation failed for active sessions',
                  error: e,
                  name: 'AttendanceSessionRepository',
                );
              }),
        );
      }
      return cached..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    }

    final query = _sessionsCol
        .where('teamId', isEqualTo: teamId)
        .where('isClosed', isEqualTo: false);

    try {
      final snapshot = await query.get(const GetOptions(source: Source.server));
      final sessions = _mapSessionsSnapshot(snapshot);
      await _localDatasource.cacheSessions(sessions);
      return sessions;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to get active sessions from server, falling back to cache',
        name: 'AttendanceSessionRepository',
        error: e,
        stackTrace: stackTrace,
      );
      try {
        final cachedSnapshot = await query.get(
          const GetOptions(source: Source.cache),
        );
        return _mapSessionsSnapshot(cachedSnapshot);
      } catch (innerError, innerStack) {
        developer.log(
          'Failed to get active sessions from cache fallback',
          name: 'AttendanceSessionRepository',
          error: innerError,
          stackTrace: innerStack,
        );
        return [];
      }
    }
  }

  /// Gets all sessions for a team.
  Future<List<AttendanceSession>> getAllSessions(String teamId) async {
    final cached = await _localDatasource.getCachedAllSessions(teamId);
    if (cached.isNotEmpty) {
      final cacheKey = 'all_sessions_$teamId';
      if (CacheTracker.shouldRevalidate(cacheKey)) {
        unawaited(
          _sessionsCol
              .where('teamId', isEqualTo: teamId)
              .get(const GetOptions(source: Source.server))
              .catchError(
                (_) => _sessionsCol
                    .where('teamId', isEqualTo: teamId)
                    .get(const GetOptions(source: Source.cache)),
              )
              .then((snapshot) {
                final sessions = _mapSessionsSnapshot(snapshot);
                if (sessions.isNotEmpty) {
                  _localDatasource.cacheSessions(sessions);
                  CacheTracker.markFetched(cacheKey);
                }
              })
              .catchError((e) {
                developer.log(
                  'Background revalidation failed for all sessions',
                  error: e,
                  name: 'AttendanceSessionRepository',
                );
              }),
        );
      }
      return cached..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    }

    final query = _sessionsCol.where('teamId', isEqualTo: teamId);

    try {
      final snapshot = await query.get(const GetOptions(source: Source.server));
      final sessions = _mapSessionsSnapshot(snapshot);
      await _localDatasource.cacheSessions(sessions);
      return sessions;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to get all sessions from server, falling back to cache',
        name: 'AttendanceSessionRepository',
        error: e,
        stackTrace: stackTrace,
      );
      try {
        final cachedSnapshot = await query.get(
          const GetOptions(source: Source.cache),
        );
        return _mapSessionsSnapshot(cachedSnapshot);
      } catch (innerError, innerStack) {
        developer.log(
          'Failed to get all sessions from cache fallback',
          name: 'AttendanceSessionRepository',
          error: innerError,
          stackTrace: innerStack,
        );
        return [];
      }
    }
  }

  /// Closes a session manually.
  Future<void> setSessionClosed({
    required String teamId,
    required String sessionId,
    required bool isClosed,
  }) async {
    // 1. Write to local Hive cache FIRST
    try {
      final cachedSession = await _localDatasource.getCachedSessionById(
        sessionId,
      );
      if (cachedSession != null) {
        final updated = cachedSession.copyWith(isClosed: isClosed);
        await _localDatasource.cacheSession(updated);
      }
    } catch (e) {
      developer.log(
        'Local cache update failed in AttendanceSessionRepository',
        error: e,
        name: 'AttendanceSessionRepository',
      );
    }

    // 2. Try online write or fallback to outbox queue
    final syncEntry = SyncEntry.create(
      id: 'close_session_$sessionId',
      action: SyncActionType.closeSession,
      payload: {'teamId': teamId, 'sessionId': sessionId, 'isClosed': isClosed},
      createdAt: DateTime.now(),
    );

    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        await _syncServiceGetter().enqueue(syncEntry);
        return;
      }

      await _sessionDoc(teamId, sessionId).update({
        'isClosed': isClosed,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      if (error.code == 'unavailable' || error.code == 'deadline-exceeded') {
        developer.log(
          'Firestore close session failed with network error, enqueuing for offline sync',
          error: error,
          name: 'AttendanceSessionRepository',
        );
        await _syncServiceGetter().enqueue(syncEntry);
      } else {
        throw mapExceptionToAttendanceFailure(error);
      }
    } catch (error) {
      developer.log(
        'Close session failed, enqueuing for offline sync',
        error: error,
        name: 'AttendanceSessionRepository',
      );
      await _syncServiceGetter().enqueue(syncEntry);
    }
  }

  Future<void> syncOfflineCloseSession(Map<String, dynamic> payload) async {
    try {
      final teamId = payload['teamId'] as String;
      final sessionId = payload['sessionId'] as String;
      final isClosed = payload['isClosed'] as bool;

      await _sessionDoc(teamId, sessionId).update({
        'isClosed': isClosed,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      if (error is AttendanceFailure) rethrow;
      throw mapExceptionToAttendanceFailure(error);
    }
  }

  /// Gets a specific session by ID (one-time read).
  Future<AttendanceSession?> getSessionById({
    required String teamId,
    required String sessionId,
  }) async {
    try {
      final cached = await _localDatasource.getCachedSessionById(sessionId);
      if (cached != null) return cached;

      final doc = await _cachedGet(_sessionDoc(teamId, sessionId));
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      final session = AttendanceSessionModel.fromMap(data, doc.id).toDomain();
      await _localDatasource.cacheSession(session);
      return session;
    } catch (error) {
      throw mapExceptionToAttendanceFailure(error);
    }
  }

  /// Gets all sessions for a specific date.
  Future<List<AttendanceSession>> getSessionsForDate({
    required String teamId,
    required String dateKey,
  }) async {
    final cached = await _localDatasource.getCachedSessionsForDate(
      teamId,
      dateKey,
    );
    if (cached.isNotEmpty) {
      final cacheKey = 'sessions_date_${teamId}_$dateKey';
      if (CacheTracker.shouldRevalidate(cacheKey)) {
        unawaited(
          _sessionsCol
              .where('teamId', isEqualTo: teamId)
              .where('dateKey', isEqualTo: dateKey)
              .get(const GetOptions(source: Source.server))
              .catchError(
                (_) => _sessionsCol
                    .where('teamId', isEqualTo: teamId)
                    .where('dateKey', isEqualTo: dateKey)
                    .get(const GetOptions(source: Source.cache)),
              )
              .then((snapshot) {
                final sessions = _mapSessionsSnapshot(snapshot);
                if (sessions.isNotEmpty) {
                  _localDatasource.cacheSessions(sessions);
                  CacheTracker.markFetched(cacheKey);
                }
              })
              .catchError((e) {
                developer.log(
                  'Background revalidation failed for sessions on date',
                  error: e,
                  name: 'AttendanceSessionRepository',
                );
              }),
        );
      }
      return cached..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    }

    final query = _sessionsCol
        .where('teamId', isEqualTo: teamId)
        .where('dateKey', isEqualTo: dateKey);

    try {
      final snapshot = await query.get(const GetOptions(source: Source.server));
      final sessions = _mapSessionsSnapshot(snapshot);
      await _localDatasource.cacheSessions(sessions);
      return sessions;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to get sessions by date key from server, falling back to cache',
        name: 'AttendanceSessionRepository',
        error: e,
        stackTrace: stackTrace,
      );
      try {
        final cachedSnapshot = await query.get(
          const GetOptions(source: Source.cache),
        );
        return _mapSessionsSnapshot(cachedSnapshot);
      } catch (innerError, innerStack) {
        developer.log(
          'Failed to get sessions by date key from cache fallback',
          name: 'AttendanceSessionRepository',
          error: innerError,
          stackTrace: innerStack,
        );
        return [];
      }
    }
  }

  /// Syncs an offline-created session.
  Future<void> syncOfflineSessionCreation(Map<String, dynamic> payload) async {
    try {
      final sessionId = payload['id'] as String;
      final teamId = payload['teamId'] as String;

      final sessionRef = _sessionDoc(teamId, sessionId);
      final teamRef = _firestore
          .collection(FirestoreCollections.classes)
          .doc(teamId);

      await _firestore.runTransaction((transaction) async {
        final sessionDoc = await transaction.get(sessionRef);
        if (sessionDoc.exists) {
          // Already synced
          return;
        }

        final teamDoc = await transaction.get(teamRef);
        List<String> openSessionIds = [];
        if (teamDoc.exists) {
          final data = teamDoc.data();
          if (data != null && data['openSessionIds'] != null) {
            openSessionIds = List<String>.from(data['openSessionIds']);
          }
        }

        if (!openSessionIds.contains(sessionId)) {
          openSessionIds.add(sessionId);
        }

        if (openSessionIds.length > 10) {
          openSessionIds.removeRange(0, openSessionIds.length - 10);
        }

        // Map payload exactly as standard session creation
        transaction.set(sessionRef, {
          ...payload,
          'teamIsActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (teamDoc.exists) {
          transaction.update(teamRef, {
            'openSessionIds': openSessionIds,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (error) {
      if (error is AttendanceFailure) rethrow;
      throw mapExceptionToAttendanceFailure(error);
    }
  }
}

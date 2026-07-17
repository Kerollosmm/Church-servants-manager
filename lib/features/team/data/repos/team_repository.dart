import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/core/constants/sync_action_type.dart';
import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/sync_service.dart';
import 'package:church_management_system/core/utils/list_extensions.dart';
import 'package:church_management_system/core/utils/sync_error_classifier.dart';
import 'package:church_management_system/features/team/data/datasources/team_local_datasource.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/domain/entities/team.dart';
import 'package:church_management_system/features/team/domain/failures/team_failures.dart';
import 'package:church_management_system/features/team/domain/repos/i_team_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Repository for team (class) data operations.
///
/// Refactored to support offline-first local cache fallback,
/// outbound sync queue enqueuing, and transactional safety.
class TeamRepository implements ITeamRepository {
  final FirebaseFirestore _firestore;
  final TeamLocalDatasource _localDatasource;
  final SyncService Function() _syncServiceGetter;
  final Connectivity _connectivity;

  TeamRepository({
    required FirebaseFirestore firestore,
    required TeamLocalDatasource localDatasource,
    required SyncService Function() syncServiceGetter,
    Connectivity? connectivity,
  }) : _firestore = firestore,
       _localDatasource = localDatasource,
       _syncServiceGetter = syncServiceGetter,
       _connectivity = connectivity ?? Connectivity();

  SyncService get _syncService => _syncServiceGetter();

  CollectionReference<Map<String, dynamic>> get _classesCollection =>
      _firestore.collection(FirestoreCollections.classes);

  CollectionReference<Map<String, dynamic>> get _registryCollection =>
      _firestore.collection(FirestoreCollections.teamUniquenessRegistry);

  CollectionReference<Map<String, dynamic>> get _studentsCollection =>
      _firestore.collection(FirestoreCollections.students);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestoreCollections.servants);

  Team? _teamFromData(
    Map<String, dynamic> data,
    String docId, {
    bool includeArchived = false,
  }) {
    final teamModel = TeamModel.fromMap(data, docId);
    if (!includeArchived && teamModel.isArchived) {
      return null;
    }
    return teamModel.toDomain();
  }

  List<Team> _teamsFromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    bool includeArchived = false,
  }) {
    final teams = <Team>[];
    for (final doc in docs) {
      final team = _teamFromData(
        doc.data(),
        doc.id,
        includeArchived: includeArchived,
      );
      if (team != null) {
        teams.add(team);
      }
    }
    return teams;
  }

  Future<void> _syncTeamNameReferences(TeamModel team) async {
    try {
      final studentsSnapshot = await _studentsCollection
          .where('classId', isEqualTo: team.id)
          .get(const GetOptions(source: Source.server));

      if (studentsSnapshot.docs.isEmpty) {
        return;
      }

      final userIds = <String>[];
      for (final studentDoc in studentsSnapshot.docs) {
        final uid = (studentDoc.data()['uid'] as String?)?.trim();
        if (uid == null || uid.isEmpty || userIds.contains(uid)) continue;
        userIds.add(uid);
      }

      final operations = <void Function(WriteBatch)>[];
      for (final studentDoc in studentsSnapshot.docs) {
        operations.add((batch) {
          batch.set(studentDoc.reference, {
            'team_name': team.name,
            'group': team.groupId,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        });
      }

      for (final chunk in userIds.chunk(10)) {
        final usersSnapshot = await _usersCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get(const GetOptions(source: Source.server));
        for (final userDoc in usersSnapshot.docs) {
          operations.add((batch) {
            batch.set(userDoc.reference, {
              'team_name': team.name,
              'groupId': team.groupId,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          });
        }
      }

      for (final chunk in operations.chunk(400)) {
        final batch = _firestore.batch();
        for (final operation in chunk) {
          operation(batch);
        }
        await batch.commit();
      }
    } catch (e) {
      developer.log('Failed to sync team name references', error: e);
    }
  }

  Future<void> _refreshTeamsByGroupCache(
    String groupId,
    bool includeArchived,
  ) async {
    try {
      final snapshot = await _classesCollection
          .where('groupId', isEqualTo: groupId)
          .get(const GetOptions(source: Source.server));
      final teams = _teamsFromDocs(
        snapshot.docs,
        includeArchived: includeArchived,
      );
      if (teams.isNotEmpty) {
        final models = teams.map(TeamModel.fromDomain).toList();
        await _localDatasource.cacheTeams(models);
      }
    } catch (_) {}
  }

  Future<void> _refreshAllTeamsCache(bool includeArchived) async {
    try {
      final baseQuery = includeArchived
          ? _classesCollection
          : _classesCollection.where('isArchived', isEqualTo: false);
      final snapshot = await baseQuery.get(
        const GetOptions(source: Source.server),
      );
      final teams = _teamsFromDocs(
        snapshot.docs,
        includeArchived: includeArchived,
      );
      if (teams.isNotEmpty) {
        final models = teams.map(TeamModel.fromDomain).toList();
        await _localDatasource.cacheTeams(models);
      }
    } catch (_) {}
  }

  Future<void> _refreshTeamByIdCache(String docId) async {
    try {
      final doc = await _classesCollection
          .doc(docId)
          .get(const GetOptions(source: Source.server));
      if (doc.exists && doc.data() != null) {
        final teamModel = TeamModel.fromMap(doc.data()!, doc.id);
        await _localDatasource.cacheTeam(teamModel);
      }
    } catch (_) {}
  }

  void _sortTeams(List<Team> teams) {
    teams.sort((a, b) {
      final groupCompare = a.groupId.compareTo(b.groupId);
      if (groupCompare != 0) return groupCompare;
      return a.name.compareTo(b.name);
    });
  }

  @override
  Future<({List<Team> teams, bool isFromCache})> getTeamsByGroupWithFallback(
    String groupId, {
    bool includeArchived = false,
  }) async {
    try {
      final cached = await _localDatasource.getCachedTeamsByGroup(
        groupId,
        includeArchived: includeArchived,
      );
      if (cached.isNotEmpty) {
        unawaited(_refreshTeamsByGroupCache(groupId, includeArchived));
        final domainTeams = cached.map((m) => m.toDomain()).toList();
        domainTeams.sort((a, b) => a.name.compareTo(b.name));
        return (teams: domainTeams, isFromCache: true);
      }
    } catch (_) {}

    try {
      final snapshot = await _classesCollection
          .where('groupId', isEqualTo: groupId)
          .get(const GetOptions(source: Source.server));

      final teams = _teamsFromDocs(
        snapshot.docs,
        includeArchived: includeArchived,
      );
      if (teams.isNotEmpty) {
        final models = teams.map(TeamModel.fromDomain).toList();
        await _localDatasource.cacheTeams(models);
      }
      teams.sort((a, b) => a.name.compareTo(b.name));
      return (teams: teams, isFromCache: false);
    } catch (e) {
      final fallback = await _localDatasource.getCachedTeamsByGroup(
        groupId,
        includeArchived: includeArchived,
      );
      final domainTeams = fallback.map((m) => m.toDomain()).toList();
      domainTeams.sort((a, b) => a.name.compareTo(b.name));
      return (teams: domainTeams, isFromCache: true);
    }
  }

  @override
  Future<List<Team>> getTeamsByGroup(
    String groupId, {
    bool includeArchived = false,
  }) async {
    try {
      final cached = await _localDatasource.getCachedTeamsByGroup(
        groupId,
        includeArchived: includeArchived,
      );
      if (cached.isNotEmpty) {
        unawaited(_refreshTeamsByGroupCache(groupId, includeArchived));
        final domainTeams = cached.map((m) => m.toDomain()).toList();
        domainTeams.sort((a, b) => a.name.compareTo(b.name));
        return domainTeams;
      }
    } catch (_) {}

    try {
      final snapshot = await _classesCollection
          .where('groupId', isEqualTo: groupId)
          .get(const GetOptions(source: Source.server));

      final teams = _teamsFromDocs(
        snapshot.docs,
        includeArchived: includeArchived,
      );
      if (teams.isNotEmpty) {
        final models = teams.map(TeamModel.fromDomain).toList();
        await _localDatasource.cacheTeams(models);
      }
      return teams..sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      final fallback = await _localDatasource.getCachedTeamsByGroup(
        groupId,
        includeArchived: includeArchived,
      );
      final domainTeams = fallback.map((m) => m.toDomain()).toList();
      domainTeams.sort((a, b) => a.name.compareTo(b.name));
      return domainTeams;
    }
  }

  @override
  Future<List<Team>> getAllTeams({bool includeArchived = false}) async {
    try {
      final cached = await _localDatasource.getCachedTeams(
        includeArchived: includeArchived,
      );
      if (cached.isNotEmpty) {
        unawaited(_refreshAllTeamsCache(includeArchived));
        final domainTeams = cached.map((m) => m.toDomain()).toList();
        _sortTeams(domainTeams);
        return domainTeams;
      }
    } catch (_) {}

    try {
      final baseQuery = includeArchived
          ? _classesCollection
          : _classesCollection.where('isArchived', isEqualTo: false);

      final snapshot = await baseQuery.get(
        const GetOptions(source: Source.server),
      );

      final teams = _teamsFromDocs(
        snapshot.docs,
        includeArchived: includeArchived,
      );
      if (teams.isNotEmpty) {
        final models = teams.map(TeamModel.fromDomain).toList();
        await _localDatasource.cacheTeams(models);
      }
      _sortTeams(teams);
      return teams;
    } catch (e) {
      final fallback = await _localDatasource.getCachedTeams(
        includeArchived: includeArchived,
      );
      final domainTeams = fallback.map((m) => m.toDomain()).toList();
      _sortTeams(domainTeams);
      return domainTeams;
    }
  }

  @override
  Future<List<Team>> getTeamsByIds(
    List<String> ids, {
    bool includeArchived = false,
  }) async {
    if (ids.isEmpty) return [];

    final localTeams = <Team>[];
    final missingIds = <String>[];

    for (final id in ids) {
      final cached = await _localDatasource.getCachedTeamById(id);
      if (cached != null) {
        if (includeArchived || !cached.isArchived) {
          localTeams.add(cached.toDomain());
        }
      } else {
        missingIds.add(id);
      }
    }

    if (missingIds.isEmpty) {
      return localTeams;
    }

    try {
      final chunks = missingIds.chunk(10);
      final futures = chunks.map(
        (chunk) => _classesCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get(const GetOptions(source: Source.server)),
      );
      final results = await Future.wait(futures);
      final docs = results.expand((snap) => snap.docs).toList();
      final fetched = _teamsFromDocs(docs, includeArchived: includeArchived);

      if (fetched.isNotEmpty) {
        final models = fetched.map(TeamModel.fromDomain).toList();
        await _localDatasource.cacheTeams(models);
      }

      return [...localTeams, ...fetched];
    } catch (e) {
      return localTeams;
    }
  }

  @override
  Future<Team?> getTeamById(String id, {bool includeArchived = false}) async {
    try {
      final cached = await _localDatasource.getCachedTeamById(id);
      if (cached != null) {
        unawaited(_refreshTeamByIdCache(id));
        return cached.toDomain();
      }
    } catch (_) {}

    try {
      final doc = await _classesCollection
          .doc(id)
          .get(const GetOptions(source: Source.server));
      if (doc.exists && doc.data() != null) {
        final teamModel = TeamModel.fromMap(doc.data()!, doc.id);
        await _localDatasource.cacheTeam(teamModel);
        return teamModel.toDomain();
      }
      return null;
    } catch (e) {
      final fallback = await _localDatasource.getCachedTeamById(id);
      return fallback?.toDomain();
    }
  }

  @override
  Future<String> createTeam(Team team) async {
    try {
      final generatedId = team.id.isNotEmpty
          ? team.id
          : _classesCollection.doc().id;
      final registryId =
          '${team.groupId.toLowerCase().trim()}_${team.name.toLowerCase().trim()}';
      final registryRef = _registryCollection.doc(registryId);

      final model = TeamModel.fromDomain(
        team,
      ).copyWith(id: generatedId, syncStatus: SyncStatus.pending);

      // Write to Hive first
      await _localDatasource.cacheTeam(model);

      final syncEntry = SyncEntry.create(
        id: 'create_team_$generatedId',
        action: SyncActionType.createTeam,
        payload: {'team': model.toMap(), 'registryId': registryId},
        createdAt: DateTime.now(),
      );

      final connectivity = await _connectivity.checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        try {
          await _syncService.enqueue(syncEntry);
        } catch (e) {
          developer.log('Failed to enqueue create team sync entry', error: e);
        }
        return generatedId;
      }

      // Try write online immediately
      try {
        await _firestore.runTransaction((transaction) async {
          final regDoc = await transaction.get(registryRef);
          if (regDoc.exists) {
            throw StateError('يوجد فريق بنفس الاسم في هذه المجموعة بالفعل');
          }

          final newDocRef = _classesCollection.doc(generatedId);
          transaction
            ..set(newDocRef, {
              ...model.toMap(),
              'updatedAt': FieldValue.serverTimestamp(),
            })
            ..set(registryRef, {
              'teamId': generatedId,
              'groupId': team.groupId,
              'teamName': team.name,
              'updatedAt': FieldValue.serverTimestamp(),
            });
        });

        // Mark synced in local database
        final syncedModel = model.copyWith(syncStatus: SyncStatus.synced);
        await _localDatasource.cacheTeam(syncedModel);
      } catch (e) {
        if (e is StateError) {
          throw TeamValidationFailure(e.message);
        }
        if (!SyncErrorClassifier.isRetriable(e)) {
          rethrow;
        }
        developer.log(
          'Create team online transaction failed, relying on offline sync queue',
          error: e,
        );
        try {
          await _syncService.enqueue(syncEntry);
        } catch (queueErr) {
          developer.log(
            'Failed to enqueue create team sync entry',
            error: queueErr,
          );
        }
      }

      return generatedId;
    } catch (e) {
      if (e is TeamValidationFailure) rethrow;
      throw mapExceptionToTeamFailure(e);
    }
  }

  @override
  Future<void> updateTeam(Team team) async {
    try {
      final model = TeamModel.fromDomain(
        team,
      ).copyWith(syncStatus: SyncStatus.pending);

      // Write to Hive first
      await _localDatasource.cacheTeam(model);

      final syncEntry = SyncEntry.create(
        id: 'update_team_${team.id}',
        action: SyncActionType.updateTeam,
        payload: model.toMap(),
        createdAt: DateTime.now(),
      );

      final connectivity = await _connectivity.checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        try {
          await _syncService.enqueue(syncEntry);
        } catch (e) {
          developer.log('Failed to enqueue update team sync entry', error: e);
        }
        return;
      }

      try {
        final teamRef = _classesCollection.doc(team.id);

        final currentDoc = await teamRef.get(
          const GetOptions(source: Source.server),
        );
        if (!currentDoc.exists || currentDoc.data() == null) {
          throw const TeamNotFoundFailure();
        }
        final existing = TeamModel.fromMap(currentDoc.data()!, currentDoc.id);
        final nameOrGroupChanged =
            team.name != existing.name || team.groupId != existing.groupId;

        await _firestore.runTransaction((transaction) async {
          final freshDoc = await transaction.get(teamRef);
          if (!freshDoc.exists || freshDoc.data() == null) {
            throw const TeamNotFoundFailure();
          }

          final freshExisting = TeamModel.fromMap(
            freshDoc.data()!,
            freshDoc.id,
          );

          if (freshExisting.name != team.name ||
              freshExisting.groupId != team.groupId) {
            final newRegistryId =
                '${team.groupId.toLowerCase().trim()}_${team.name.toLowerCase().trim()}';
            final oldRegistryId =
                '${freshExisting.groupId.toLowerCase().trim()}_${freshExisting.name.toLowerCase().trim()}';

            final newRegDoc = await transaction.get(
              _registryCollection.doc(newRegistryId),
            );

            if (newRegDoc.exists) {
              final regTeamId = newRegDoc.data()?['teamId'];
              if (regTeamId != team.id) {
                throw StateError('يوجد فريق بنفس الاسم في هذه المجموعة بالفعل');
              }
            }

            if (oldRegistryId != newRegistryId) {
              transaction.delete(_registryCollection.doc(oldRegistryId));
            }
            transaction.set(_registryCollection.doc(newRegistryId), {
              'teamId': team.id,
              'groupId': team.groupId,
              'teamName': team.name,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          transaction.update(teamRef, {
            ...model.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });

        if (nameOrGroupChanged) {
          await _syncTeamNameReferences(model);
        }

        final syncedModel = model.copyWith(syncStatus: SyncStatus.synced);
        await _localDatasource.cacheTeam(syncedModel);
      } catch (e) {
        if (e is TeamNotFoundFailure) rethrow;
        if (e is StateError) {
          throw TeamValidationFailure(e.message);
        }
        if (!SyncErrorClassifier.isRetriable(e)) {
          rethrow;
        }
        developer.log(
          'Update team online transaction failed, relying on offline sync queue',
          error: e,
        );
        try {
          await _syncService.enqueue(syncEntry);
        } catch (queueErr) {
          developer.log(
            'Failed to enqueue update team sync entry',
            error: queueErr,
          );
        }
      }
    } catch (e) {
      if (e is TeamFailure) rethrow;
      throw mapExceptionToTeamFailure(e);
    }
  }

  @override
  Future<void> deleteTeam(String id) async {
    try {
      final existingModel = await _localDatasource.getCachedTeamById(id);
      if (existingModel != null) {
        final updated = existingModel.copyWith(
          isArchived: true,
          archivedAt: DateTime.now(),
          archiveReason: 'Archived from app',
          assignedServantId: null,
          assignedServantName: null,
          syncStatus: SyncStatus.pending,
        );
        await _localDatasource.cacheTeam(updated);
      }

      final syncEntry = SyncEntry.create(
        id: 'delete_team_$id',
        action: SyncActionType.deleteTeam,
        payload: {'id': id},
        createdAt: DateTime.now(),
      );

      final connectivity = await _connectivity.checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        try {
          await _syncService.enqueue(syncEntry);
        } catch (e) {
          developer.log('Failed to enqueue delete team sync entry', error: e);
        }
        return;
      }

      try {
        final teamRef = _classesCollection.doc(id);

        await _firestore.runTransaction((transaction) async {
          final teamDoc = await transaction.get(teamRef);
          final teamData = teamDoc.data();
          if (!teamDoc.exists || teamData == null) {
            throw const TeamNotFoundFailure();
          }

          final team = TeamModel.fromMap(teamData, teamDoc.id);
          if (team.isArchived) {
            return;
          }

          final assignedServantId =
              (teamData['assignedServantId'] as String? ??
                      teamData['assigned_servant_id'] as String?)
                  ?.trim();
          if (assignedServantId != null && assignedServantId.isNotEmpty) {
            final servantRef = _usersCollection.doc(assignedServantId);
            final servantDoc = await transaction.get(servantRef);
            final servantData = servantDoc.data();

            if (servantDoc.exists && servantData != null) {
              final assignedIds = <String>[];
              final rawIds = servantData['assignedTeamIds'];
              if (rawIds is Iterable) {
                for (final value in rawIds) {
                  final normalized = value?.toString().trim() ?? '';
                  if (normalized.isEmpty ||
                      normalized == id ||
                      assignedIds.contains(normalized)) {
                    continue;
                  }
                  assignedIds.add(normalized);
                }
              }

              transaction.update(servantRef, {
                'assignedTeamIds': assignedIds.isEmpty
                    ? FieldValue.delete()
                    : assignedIds,
                'assignedTeamId': assignedIds.isEmpty
                    ? FieldValue.delete()
                    : assignedIds.first,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }

          final registryId = '${team.groupId}_${team.name}';
          transaction
            ..delete(_registryCollection.doc(registryId))
            ..set(teamRef, {
              'isArchived': true,
              'archivedAt': FieldValue.serverTimestamp(),
              'archiveReason': 'Archived from app',
              'assignedServantId': FieldValue.delete(),
              'assignedServantName': FieldValue.delete(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        });

        if (existingModel != null) {
          final synced = existingModel.copyWith(
            isArchived: true,
            archivedAt: DateTime.now(),
            archiveReason: 'Archived from app',
            assignedServantId: null,
            assignedServantName: null,
            syncStatus: SyncStatus.synced,
          );
          await _localDatasource.cacheTeam(synced);
        }
      } catch (e) {
        if (e is TeamNotFoundFailure) rethrow;
        if (!SyncErrorClassifier.isRetriable(e)) {
          rethrow;
        }
        developer.log(
          'Delete team online transaction failed, relying on offline sync queue',
          error: e,
        );
        try {
          await _syncService.enqueue(syncEntry);
        } catch (queueErr) {
          developer.log(
            'Failed to enqueue delete team sync entry',
            error: queueErr,
          );
        }
      }
    } catch (e) {
      if (e is TeamFailure) rethrow;
      throw mapExceptionToTeamFailure(e);
    }
  }

  @override
  Future<void> restoreTeam(String id) async {
    try {
      final existingModel = await _localDatasource.getCachedTeamById(id);
      if (existingModel != null) {
        final updated = existingModel.copyWith(
          isArchived: false,
          restoredAt: DateTime.now(),
          restoredByUserId: 'system',
          syncStatus: SyncStatus.pending,
        );
        await _localDatasource.cacheTeam(updated);
      }

      final syncEntry = SyncEntry.create(
        id: 'restore_team_$id',
        action: SyncActionType.restoreTeam,
        payload: {'id': id},
        createdAt: DateTime.now(),
      );

      final connectivity = await _connectivity.checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        try {
          await _syncService.enqueue(syncEntry);
        } catch (e) {
          developer.log('Failed to enqueue restore team sync entry', error: e);
        }
        return;
      }

      try {
        final teamRef = _classesCollection.doc(id);

        await _firestore.runTransaction((transaction) async {
          final teamDoc = await transaction.get(teamRef);
          final teamData = teamDoc.data();
          if (!teamDoc.exists || teamData == null) {
            throw const TeamNotFoundFailure();
          }

          final team = TeamModel.fromMap(teamData, teamDoc.id);

          final registryId =
              '${team.groupId.toLowerCase().trim()}_${team.name.toLowerCase().trim()}';
          final registryRef = _registryCollection.doc(registryId);

          final regDoc = await transaction.get(registryRef);
          if (regDoc.exists) {
            throw StateError(
              'يوجد فريق بنفس الاسم في هذه المجموعة بالفعل. الرجاء تغيير اسم الفريق النشط أولاً.',
            );
          }

          transaction.set(registryRef, {
            'teamId': team.id,
            'groupId': team.groupId,
            'teamName': team.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          transaction.set(teamRef, {
            'isArchived': false,
            'restoredAt': FieldValue.serverTimestamp(),
            'restoredByUserId': 'system',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          final assignedServantId = (teamData['assignedServantId'] as String?)
              ?.trim();
          if (assignedServantId != null && assignedServantId.isNotEmpty) {
            final servantRef = _usersCollection.doc(assignedServantId);
            transaction.set(servantRef, {
              'assignedTeamIds': FieldValue.arrayUnion([team.id]),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        });

        if (existingModel != null) {
          final synced = existingModel.copyWith(
            isArchived: false,
            restoredAt: DateTime.now(),
            restoredByUserId: 'system',
            syncStatus: SyncStatus.synced,
          );
          await _localDatasource.cacheTeam(synced);
        }
      } catch (e) {
        if (e is TeamNotFoundFailure) rethrow;
        if (e is StateError) {
          throw TeamValidationFailure(e.message);
        }
        if (!SyncErrorClassifier.isRetriable(e)) {
          rethrow;
        }
        developer.log(
          'Restore team online transaction failed, relying on offline sync queue',
          error: e,
        );
        try {
          await _syncService.enqueue(syncEntry);
        } catch (queueErr) {
          developer.log(
            'Failed to enqueue restore team sync entry',
            error: queueErr,
          );
        }
      }
    } catch (e) {
      if (e is TeamFailure) rethrow;
      throw mapExceptionToTeamFailure(e);
    }
  }

  @override
  Future<void> syncOfflineCreate(Map<String, dynamic> payload) async {
    try {
      final teamData = payload['team'] as Map<String, dynamic>;
      final registryId = payload['registryId'] as String;
      final teamId = teamData['id'] as String;

      final model = TeamModel.fromMap(teamData, teamId);
      final registryRef = _registryCollection.doc(registryId);

      await _firestore.runTransaction((transaction) async {
        final regDoc = await transaction.get(registryRef);
        if (regDoc.exists) {
          final existingTeamId = regDoc.data()?['teamId'];
          if (existingTeamId != teamId) {
            throw StateError('يوجد فريق بنفس الاسم في هذه المجموعة بالفعل');
          }
        }

        final newDocRef = _classesCollection.doc(teamId);
        transaction
          ..set(newDocRef, {
            ...model.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          ..set(registryRef, {
            'teamId': teamId,
            'groupId': model.groupId,
            'teamName': model.name,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      });

      final syncedModel = model.copyWith(syncStatus: SyncStatus.synced);
      await _localDatasource.cacheTeam(syncedModel);
    } catch (e) {
      throw mapExceptionToTeamFailure(e);
    }
  }

  @override
  Future<void> syncOfflineUpdate(Map<String, dynamic> payload) async {
    try {
      final teamId = payload['id'] as String;
      final model = TeamModel.fromMap(payload, teamId);
      final teamRef = _classesCollection.doc(teamId);

      final currentDoc = await teamRef.get(
        const GetOptions(source: Source.server),
      );
      if (!currentDoc.exists || currentDoc.data() == null) {
        throw const TeamNotFoundFailure();
      }
      final existing = TeamModel.fromMap(currentDoc.data()!, currentDoc.id);
      final nameOrGroupChanged =
          model.name != existing.name || model.groupId != existing.groupId;

      await _firestore.runTransaction((transaction) async {
        final freshDoc = await transaction.get(teamRef);
        if (!freshDoc.exists || freshDoc.data() == null) {
          throw const TeamNotFoundFailure();
        }

        final freshExisting = TeamModel.fromMap(freshDoc.data()!, freshDoc.id);

        if (freshExisting.name != model.name ||
            freshExisting.groupId != model.groupId) {
          final newRegistryId =
              '${model.groupId.toLowerCase().trim()}_${model.name.toLowerCase().trim()}';
          final oldRegistryId =
              '${freshExisting.groupId.toLowerCase().trim()}_${freshExisting.name.toLowerCase().trim()}';

          final newRegDoc = await transaction.get(
            _registryCollection.doc(newRegistryId),
          );

          if (newRegDoc.exists) {
            final regTeamId = newRegDoc.data()?['teamId'];
            if (regTeamId != model.id) {
              throw StateError('يوجد فريق بنفس الاسم في هذه المجموعة بالفعل');
            }
          }

          if (oldRegistryId != newRegistryId) {
            transaction.delete(_registryCollection.doc(oldRegistryId));
          }
          transaction.set(_registryCollection.doc(newRegistryId), {
            'teamId': model.id,
            'groupId': model.groupId,
            'teamName': model.name,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        transaction.update(teamRef, {
          ...model.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (nameOrGroupChanged) {
        await _syncTeamNameReferences(model);
      }

      final syncedModel = model.copyWith(syncStatus: SyncStatus.synced);
      await _localDatasource.cacheTeam(syncedModel);
    } catch (e) {
      throw mapExceptionToTeamFailure(e);
    }
  }

  @override
  Future<void> syncOfflineDelete(Map<String, dynamic> payload) async {
    try {
      final id = payload['id'] as String;
      final teamRef = _classesCollection.doc(id);

      await _firestore.runTransaction((transaction) async {
        final teamDoc = await transaction.get(teamRef);
        final teamData = teamDoc.data();
        if (!teamDoc.exists || teamData == null) {
          throw const TeamNotFoundFailure();
        }

        final team = TeamModel.fromMap(teamData, teamDoc.id);
        if (team.isArchived) {
          return;
        }

        final assignedServantId =
            (teamData['assignedServantId'] as String? ??
                    teamData['assigned_servant_id'] as String?)
                ?.trim();
        if (assignedServantId != null && assignedServantId.isNotEmpty) {
          final servantRef = _usersCollection.doc(assignedServantId);
          final servantDoc = await transaction.get(servantRef);
          final servantData = servantDoc.data();

          if (servantDoc.exists && servantData != null) {
            final assignedIds = <String>[];
            final rawIds = servantData['assignedTeamIds'];
            if (rawIds is Iterable) {
              for (final value in rawIds) {
                final normalized = value?.toString().trim() ?? '';
                if (normalized.isEmpty ||
                    normalized == id ||
                    assignedIds.contains(normalized)) {
                  continue;
                }
                assignedIds.add(normalized);
              }
            }

            transaction.update(servantRef, {
              'assignedTeamIds': assignedIds.isEmpty
                  ? FieldValue.delete()
                  : assignedIds,
              'assignedTeamId': assignedIds.isEmpty
                  ? FieldValue.delete()
                  : assignedIds.first,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        final registryId = '${team.groupId}_${team.name}';
        transaction
          ..delete(_registryCollection.doc(registryId))
          ..set(teamRef, {
            'isArchived': true,
            'archivedAt': FieldValue.serverTimestamp(),
            'archiveReason': 'Archived from app',
            'assignedServantId': FieldValue.delete(),
            'assignedServantName': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      });

      final existingModel = await _localDatasource.getCachedTeamById(id);
      if (existingModel != null) {
        final synced = existingModel.copyWith(
          isArchived: true,
          archivedAt: DateTime.now(),
          archiveReason: 'Archived from app',
          assignedServantId: null,
          assignedServantName: null,
          syncStatus: SyncStatus.synced,
        );
        await _localDatasource.cacheTeam(synced);
      }
    } catch (e) {
      throw mapExceptionToTeamFailure(e);
    }
  }

  @override
  Future<void> syncOfflineRestore(Map<String, dynamic> payload) async {
    try {
      final id = payload['id'] as String;
      final teamRef = _classesCollection.doc(id);

      await _firestore.runTransaction((transaction) async {
        final teamDoc = await transaction.get(teamRef);
        final teamData = teamDoc.data();
        if (!teamDoc.exists || teamData == null) {
          throw const TeamNotFoundFailure();
        }

        final team = TeamModel.fromMap(teamData, teamDoc.id);

        final registryId =
            '${team.groupId.toLowerCase().trim()}_${team.name.toLowerCase().trim()}';
        final registryRef = _registryCollection.doc(registryId);

        final regDoc = await transaction.get(registryRef);
        if (regDoc.exists) {
          final existingTeamId = regDoc.data()?['teamId'];
          if (existingTeamId != id) {
            throw StateError(
              'يوجد فريق بنفس الاسم في هذه المجموعة بالفعل. الرجاء تغيير اسم الفريق النشط أولاً.',
            );
          }
        }

        transaction.set(registryRef, {
          'teamId': team.id,
          'groupId': team.groupId,
          'teamName': team.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        transaction.set(teamRef, {
          'isArchived': false,
          'restoredAt': FieldValue.serverTimestamp(),
          'restoredByUserId': 'system',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        final assignedServantId = (teamData['assignedServantId'] as String?)
            ?.trim();
        if (assignedServantId != null && assignedServantId.isNotEmpty) {
          final servantRef = _usersCollection.doc(assignedServantId);
          transaction.set(servantRef, {
            'assignedTeamIds': FieldValue.arrayUnion([team.id]),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      });

      final existingModel = await _localDatasource.getCachedTeamById(id);
      if (existingModel != null) {
        final synced = existingModel.copyWith(
          isArchived: false,
          restoredAt: DateTime.now(),
          restoredByUserId: 'system',
          syncStatus: SyncStatus.synced,
        );
        await _localDatasource.cacheTeam(synced);
      }
    } catch (e) {
      throw mapExceptionToTeamFailure(e);
    }
  }
}

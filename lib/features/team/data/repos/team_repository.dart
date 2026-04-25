import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/core/utils/list_extensions.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/domain/failures/team_failures.dart';
import 'package:church_management_system/features/team/domain/repos/i_team_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Repository for team (class) data operations.
///
/// Handles team CRUD, member assignment, and name
/// denormalization across students and users.
class TeamRepository implements ITeamRepository {
  final FirebaseFirestore _firestore;

  TeamRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _classesCollection =>
      _firestore.collection(FirestoreCollections.classes);

  CollectionReference<Map<String, dynamic>> get _registryCollection =>
      _firestore.collection('team_uniqueness_registry');
  CollectionReference<Map<String, dynamic>> get _studentsCollection =>
      _firestore.collection(FirestoreCollections.students);
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestoreCollections.users);

  TeamModel? _teamFromData(
    Map<String, dynamic> data,
    String docId, {
    bool includeArchived = false,
  }) {
    final team = TeamModel.fromMap(data, docId);
    if (!includeArchived && team.isArchived) {
      return null;
    }
    return team;
  }

  List<TeamModel> _teamsFromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    bool includeArchived = false,
  }) {
    final teams = <TeamModel>[];
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
    final studentsSnapshot = await _studentsCollection
        .where('classId', isEqualTo: team.id)
        .get();

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

    for (final chunk in userIds.chunk(30)) {
      final usersSnapshot = await _usersCollection
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
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
  }

  @override
  Future<List<TeamModel>> getTeamsByGroup(
    String groupId, {
    bool includeArchived = false,
  }) async {
    try {
      try {
        final cacheSnapshot = await _classesCollection
            .where('groupId', isEqualTo: groupId)
            .get(const GetOptions(source: Source.cache));

        if (cacheSnapshot.docs.isNotEmpty) {
          final teams = _teamsFromDocs(
            cacheSnapshot.docs,
            includeArchived: includeArchived,
          );
          teams.sort((a, b) => a.name.compareTo(b.name));
          return teams;
        }
      } catch (_) {}

      final snapshot = await _classesCollection
          .where('groupId', isEqualTo: groupId)
          .get(const GetOptions(source: Source.server));

      final teams = _teamsFromDocs(
        snapshot.docs,
        includeArchived: includeArchived,
      );
      teams.sort((a, b) => a.name.compareTo(b.name));
      return teams;
    } catch (e) {
      throw mapExceptionToTeamFailure(e);
    }
  }

  @override
  Stream<List<TeamModel>> watchTeamsByGroup(
    String groupId, {
    bool includeArchived = false,
  }) {
    return _classesCollection
        .where('groupId', isEqualTo: groupId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return _teamsFromDocs(
            snapshot.docs,
            includeArchived: includeArchived,
          );
        });
  }

  @override
  Future<List<TeamModel>> getAllTeams({bool includeArchived = false}) async {
    try {
      final baseQuery = includeArchived
          ? _classesCollection
          : _classesCollection.where('isArchived', isEqualTo: false);

      final snapshot = await baseQuery.get();

      final teams = _teamsFromDocs(
        snapshot.docs,
        includeArchived: includeArchived,
      );
      teams.sort((a, b) {
        final groupCompare = a.groupId.compareTo(b.groupId);
        if (groupCompare != 0) return groupCompare;
        return a.name.compareTo(b.name);
      });
      return teams;
    } catch (e) {
      throw mapExceptionToTeamFailure(e);
    }
  }

  @override
  Future<List<TeamModel>> getTeamsByIds(
    List<String> ids, {
    bool includeArchived = false,
  }) async {
    if (ids.isEmpty) return [];
    try {
      final chunks = ids.chunk(30);
      final futures = chunks.map(
        (chunk) => _classesCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get(),
      );
      final results = await Future.wait(futures);
      final docs = results.expand((snap) => snap.docs).toList();
      return _teamsFromDocs(docs, includeArchived: includeArchived);
    } catch (e) {
      throw mapExceptionToTeamFailure(e);
    }
  }

  @override
  Stream<List<TeamModel>> watchAllTeams({bool includeArchived = false}) {
    final query = includeArchived
        ? _classesCollection
        : _classesCollection.where('isArchived', isEqualTo: false);
    return query.orderBy('groupId').orderBy('name').snapshots().map((snapshot) {
      return _teamsFromDocs(snapshot.docs, includeArchived: includeArchived);
    });
  }

  @override
  Future<TeamModel?> getTeamById(
    String id, {
    bool includeArchived = false,
  }) async {
    try {
      final doc = await _classesCollection.doc(id).get();
      if (doc.exists && doc.data() != null) {
        return _teamFromData(
          doc.data()!,
          doc.id,
          includeArchived: includeArchived,
        );
      }
      return null;
    } catch (e) {
      throw mapExceptionToTeamFailure(e);
    }
  }

  @override
  Future<String> createTeam(TeamModel team) async {
    try {
      final registryId =
          '${team.groupId.toLowerCase().trim()}_${team.name.toLowerCase().trim()}';
      final registryRef = _registryCollection.doc(registryId);

      final docRef = await _firestore.runTransaction((transaction) async {
        final regDoc = await transaction.get(registryRef);
        if (regDoc.exists) {
          throw StateError('يوجد فريق بنفس الاسم في هذه المجموعة بالفعل');
        }

        final newDocRef = _classesCollection.doc();
        transaction.set(newDocRef, {
          ...team.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.set(registryRef, {
          'teamId': newDocRef.id,
          'groupId': team.groupId,
          'teamName': team.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return newDocRef;
      });
      return docRef.id;
    } catch (e) {
      if (e is StateError) {
        throw TeamValidationFailure(e.message);
      }
      throw mapExceptionToTeamFailure(e);
    }
  }

  @override
  Future<void> updateTeam(TeamModel team) async {
    try {
      final teamRef = _classesCollection.doc(team.id);

      final currentDoc = await teamRef.get();
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

        final freshExisting = TeamModel.fromMap(freshDoc.data()!, freshDoc.id);

        // If name or group changed, handle uniqueness registry
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

          // Release old registry and claim new one
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
          ...team.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Sync team name references only when name or group changed
      if (nameOrGroupChanged) {
        await _syncTeamNameReferences(team);
      }
    } catch (e) {
      if (e is StateError) {
        throw TeamValidationFailure(e.message);
      }
      throw mapExceptionToTeamFailure(e);
    }
  }

  @override
  Future<void> deleteTeam(String id) async {
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

        final assignedServantId = (teamData['assignedServantId'] as String?)
            ?.trim();
        if (assignedServantId != null && assignedServantId.isNotEmpty) {
          // We can't call another async method that does its own transaction/gets here easily,
          // so we'll handle the servant update after the transaction or implement it here.
          // Since we want atomicity, let's implement it here.
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

            transaction.set(servantRef, {
              'assignedTeamIds': assignedIds.isEmpty
                  ? FieldValue.delete()
                  : assignedIds,
              'assignedTeamId': assignedIds.isEmpty
                  ? FieldValue.delete()
                  : assignedIds.first,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }

        // Cleanup registry
        final registryId = '${team.groupId}_${team.name}';
        transaction.delete(_registryCollection.doc(registryId));

        // Archive team
        transaction.set(teamRef, {
          'isArchived': true,
          'archivedAt': FieldValue.serverTimestamp(),
          'archiveReason': 'Archived from app',
          'assignedServantId': FieldValue.delete(),
          'assignedServantName': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      if (e is TeamFailure) rethrow;
      throw mapExceptionToTeamFailure(e);
    }
  }

  @override
  Future<void> restoreTeam(String id) async {
    try {
      final teamRef = _classesCollection.doc(id);
      final teamDoc = await teamRef.get();
      final teamData = teamDoc.data();
      if (!teamDoc.exists || teamData == null) {
        throw const TeamNotFoundFailure();
      }

      await teamRef.set({
        'isArchived': false,
        'restoredAt': FieldValue.serverTimestamp(),
        'restoredByUserId': 'system',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw mapExceptionToTeamFailure(e);
    }
  }
}

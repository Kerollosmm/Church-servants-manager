import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/domain/failures/team_failures.dart';
import 'package:church_management_system/features/team/domain/repos/i_team_repository.dart';

class TeamRepository implements ITeamRepository {
  final FirebaseFirestore _firestore;

  TeamRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _classesCollection =>
      _firestore.collection(FirestoreCollections.classes);
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

  List<List<T>> _chunkList<T>(List<T> values, int size) {
    final chunks = <List<T>>[];
    for (var index = 0; index < values.length; index += size) {
      final end = index + size > values.length ? values.length : index + size;
      chunks.add(values.sublist(index, end));
    }
    return chunks;
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

    for (final chunk in _chunkList(userIds, 10)) {
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

    for (final chunk in _chunkList(operations, 400)) {
      final batch = _firestore.batch();
      for (final operation in chunk) {
        operation(batch);
      }
      await batch.commit();
    }
  }

  Future<void> _removeTeamAssignmentFromServant(String servantId, String teamId) async {
    final servantRef = _usersCollection.doc(servantId);
    final servantDoc = await servantRef.get();
    final data = servantDoc.data();
    if (!servantDoc.exists || data == null) {
      return;
    }

    final assignedIds = <String>[];
    final rawIds = data['assignedTeamIds'];
    if (rawIds is Iterable) {
      for (final value in rawIds) {
        final normalized = value?.toString().trim() ?? '';
        if (normalized.isEmpty || normalized == teamId || assignedIds.contains(normalized)) {
          continue;
        }
        assignedIds.add(normalized);
      }
    }

    final legacyAssignedId = (data['assignedTeamId'] as String?)?.trim();
    if (legacyAssignedId != null &&
        legacyAssignedId.isNotEmpty &&
        legacyAssignedId != teamId &&
        !assignedIds.contains(legacyAssignedId)) {
      assignedIds.add(legacyAssignedId);
    }

    await servantRef.set({
      'assignedTeamIds': assignedIds.isEmpty ? FieldValue.delete() : assignedIds,
      'assignedTeamId': assignedIds.isEmpty
          ? FieldValue.delete()
          : assignedIds.first,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<List<TeamModel>> getTeamsByGroup(
    String groupId, {
    bool includeArchived = false,
    bool forceServer = false,
  }) async {
    try {
      if (!forceServer) {
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
      }

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
  Future<List<TeamModel>> getAllTeams({bool includeArchived = false, bool forceServer = false}) async {
    try {
      if (!forceServer) {
        try {
          final cacheSnapshot = await _classesCollection.get(
            const GetOptions(source: Source.cache),
          );
          if (cacheSnapshot.docs.isNotEmpty) {
            final teams = _teamsFromDocs(
              cacheSnapshot.docs,
              includeArchived: includeArchived,
            );
            teams.sort((a, b) {
              final groupCompare = a.groupId.compareTo(b.groupId);
              if (groupCompare != 0) return groupCompare;
              return a.name.compareTo(b.name);
            });
            return teams;
          }
        } catch (_) {}
      }

      final snapshot = await _classesCollection.get(
        const GetOptions(source: Source.server),
      );

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
  Stream<List<TeamModel>> watchAllTeams({bool includeArchived = false}) {
    return _classesCollection
        .orderBy('groupId')
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
  Future<TeamModel?> getTeamById(String id, {bool includeArchived = false}) async {
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
      final docRef = await _classesCollection.add(team.toMap());
      return docRef.id;
    } catch (e) {
      throw mapExceptionToTeamFailure(e);
    }
  }

  @override
  Future<void> updateTeam(TeamModel team) async {
    try {
      final teamRef = _classesCollection.doc(team.id);
      final existingDoc = await teamRef.get();
      if (!existingDoc.exists || existingDoc.data() == null) {
        throw const TeamNotFoundFailure();
      }

      final existing = TeamModel.fromMap(existingDoc.data()!, existingDoc.id);
      await teamRef.update({
        ...team.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (existing.name != team.name || existing.groupId != team.groupId) {
        await _syncTeamNameReferences(team);
      }
    } catch (e) {
      throw mapExceptionToTeamFailure(e);
    }
  }

  @override
  Future<void> deleteTeam(String id) async {
    try {
      final teamRef = _classesCollection.doc(id);
      final teamDoc = await teamRef.get();
      final teamData = teamDoc.data();
      if (!teamDoc.exists || teamData == null) {
        throw const TeamNotFoundFailure();
      }

      final team = TeamModel.fromMap(teamData, teamDoc.id);
      if (team.isArchived) {
        return;
      }

      final assignedServantId = (teamData['assignedServantId'] as String?)?.trim();
      if (assignedServantId != null && assignedServantId.isNotEmpty) {
        await _removeTeamAssignmentFromServant(assignedServantId, id);
      }

      await teamRef.set({
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
        'archiveReason': 'Archived from app',
        'assignedServantId': FieldValue.delete(),
        'assignedServantName': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
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

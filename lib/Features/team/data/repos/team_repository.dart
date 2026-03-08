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

  @override
  Future<List<TeamModel>> getTeamsByGroup(String groupId) async {
    try {
      try {
        final cacheSnapshot = await _classesCollection
            .where('groupId', isEqualTo: groupId)
            .get(const GetOptions(source: Source.cache));

        if (cacheSnapshot.docs.isNotEmpty) {
          final teams = cacheSnapshot.docs
              .map((doc) => TeamModel.fromMap(doc.data(), doc.id))
              .toList();
          teams.sort((a, b) => a.name.compareTo(b.name));
          return teams;
        }
      } catch (_) {}

      final snapshot = await _classesCollection
          .where('groupId', isEqualTo: groupId)
          .get(const GetOptions(source: Source.server));

      final teams = snapshot.docs
          .map((doc) => TeamModel.fromMap(doc.data(), doc.id))
          .toList();
      teams.sort((a, b) => a.name.compareTo(b.name));
      return teams;
    } catch (e) {
      throw mapExceptionToTeamFailure(e);
    }
  }

  @override
  Stream<List<TeamModel>> watchTeamsByGroup(String groupId) {
    return _classesCollection
        .where('groupId', isEqualTo: groupId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TeamModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Future<List<TeamModel>> getAllTeams() async {
    try {
      try {
        final cacheSnapshot = await _classesCollection.get(
          const GetOptions(source: Source.cache),
        );
        if (cacheSnapshot.docs.isNotEmpty) {
          final teams = cacheSnapshot.docs
              .map((doc) => TeamModel.fromMap(doc.data(), doc.id))
              .toList();
          teams.sort((a, b) {
            final groupCompare = a.groupId.compareTo(b.groupId);
            if (groupCompare != 0) return groupCompare;
            return a.name.compareTo(b.name);
          });
          return teams;
        }
      } catch (_) {}

      final snapshot = await _classesCollection.get(
        const GetOptions(source: Source.server),
      );

      final teams = snapshot.docs
          .map((doc) => TeamModel.fromMap(doc.data(), doc.id))
          .toList();
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
  Stream<List<TeamModel>> watchAllTeams() {
    return _classesCollection
        .orderBy('groupId')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TeamModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Future<TeamModel?> getTeamById(String id) async {
    try {
      final doc = await _classesCollection.doc(id).get();
      if (doc.exists && doc.data() != null) {
        return TeamModel.fromMap(doc.data()!, doc.id);
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
      await _classesCollection.doc(team.id).update(team.toMap());
    } catch (e) {
      throw mapExceptionToTeamFailure(e);
    }
  }

  @override
  Future<void> deleteTeam(String id) async {
    try {
      await _classesCollection.doc(id).delete();
    } catch (e) {
      throw mapExceptionToTeamFailure(e);
    }
  }
}

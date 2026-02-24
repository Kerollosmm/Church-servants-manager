import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/constants/firestore_collections.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/servant/data/models/servant_models.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/team/data/models/team_model.dart';
import 'package:injectable/injectable.dart';

/// Admin-only operations that touch multiple collections.
///
/// Feature: Teams
/// - Admin assigns a servant responsible for a team.
/// - Admin assigns/removes students to/from a team.
///
/// NOTE: Permissions must be enforced by Firestore Security Rules.
@lazySingleton
class AdminTeamService {
  final FirebaseFirestore _firestore;

  AdminTeamService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _classes =>
      _firestore.collection(FirestoreCollections.classes);
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);
  CollectionReference<Map<String, dynamic>> get _students =>
      _firestore.collection(FirestoreCollections.students);

  void _assertAdmin(AuthUser actor) {
    if (actor.role != UserRole.admin) {
      throw StateError('Permission denied: admin only');
    }
  }

  void _validateServantForTeam({
    required TeamModel team,
    required String servantDocId,
    required Map<String, dynamic> servantData,
  }) {
    final role = (servantData['role'] as String?)?.trim().toLowerCase();
    if (role != UserRole.servant.name) {
      throw StateError('Selected user is not a servant');
    }

    final groupId = (servantData['groupId'] as String?)?.trim();
    if (groupId == null || groupId.isEmpty) {
      throw StateError(
        'Selected servant ($servantDocId) is missing group assignment',
      );
    }
    if (groupId != team.groupId) {
      throw StateError(
        'Cannot assign servant from group "$groupId" to team group "${team.groupId}"',
      );
    }
  }

  List<String> _extractAssignedTeamIds(Map<String, dynamic> data) {
    final ids = <String>[];

    final assignedTeamIds = data['assignedTeamIds'];
    if (assignedTeamIds is Iterable) {
      for (final value in assignedTeamIds) {
        if (value is! String) continue;
        final id = value.trim();
        if (id.isEmpty || ids.contains(id)) continue;
        ids.add(id);
      }
    }

    final assignedTeamId = data['assignedTeamId'];
    if (assignedTeamId is String) {
      final id = assignedTeamId.trim();
      if (id.isNotEmpty && !ids.contains(id)) {
        ids.add(id);
      }
    }

    return ids;
  }

  Future<void> _removeTeamFromServant(
    Transaction transaction,
    DocumentReference<Map<String, dynamic>> servantRef,
    String teamId,
  ) async {
    final servantSnap = await transaction.get(servantRef);
    if (servantSnap.exists) {
      final teamIds = _extractAssignedTeamIds(
        servantSnap.data() ?? <String, dynamic>{},
      )..removeWhere((id) => id == teamId);
      transaction.set(
        servantRef,
        _servantAssignmentPatch(teamIds),
        SetOptions(merge: true),
      );
    }
  }

  Map<String, dynamic> _servantAssignmentPatch(List<String> teamIds) {
    if (teamIds.isEmpty) {
      return {
        'assignedTeamIds': FieldValue.delete(),
        'assignedTeamId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
    }
    return {
      'assignedTeamIds': teamIds,
      // Keep legacy field for backward compatibility.
      'assignedTeamId': teamIds.first,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> _recomputeStudentIdsForClasses(Set<String> classIds) async {
    final normalizedClassIds = classIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    if (normalizedClassIds.isEmpty) return;

    final pendingIds = normalizedClassIds.toList(growable: false);
    for (var i = 0; i < pendingIds.length; i += 200) {
      final batch = _firestore.batch();
      final end = (i + 200 > pendingIds.length) ? pendingIds.length : i + 200;
      final slice = pendingIds.sublist(i, end);

      for (final classId in slice) {
        final membersSnap = await _students
            .where('classId', isEqualTo: classId)
            .get();
        final memberIds = membersSnap.docs
            .map((studentDoc) => studentDoc.id)
            .toList(growable: false);
        batch.set(_classes.doc(classId), {
          'student_ids': memberIds,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
    }
  }

  /// Assign [servant] as the responsible servant for [team].
  ///
  /// Updates:
  /// - Classes/{teamId}: assignedServantId + assignedServantName
  /// - Users/{servantDocId}: assignedTeamIds (+ legacy assignedTeamId)
  /// - If the team had a previous servant, removes this team from their list.
  Future<void> assignServantToTeam({
    required AuthUser actor,
    required TeamModel team,
    required ServantModel servant,
  }) async {
    _assertAdmin(actor);

    final teamRef = _classes.doc(team.id);
    final newServantRef = _users.doc(servant.docID);

    await _firestore.runTransaction((transaction) async {
      final teamSnap = await transaction.get(teamRef);
      if (!teamSnap.exists) {
        throw StateError('Team not found');
      }

      final teamData = teamSnap.data() ?? <String, dynamic>{};
      final oldServantId = (teamData['assignedServantId'] as String?)?.trim();
      final oldServantRef = oldServantId == null || oldServantId.isEmpty
          ? null
          : _users.doc(oldServantId);

      final newServantSnap = await transaction.get(newServantRef);
      final newServantData = newServantSnap.data();
      if (!newServantSnap.exists || newServantData == null) {
        throw StateError('Servant not found');
      }
      _validateServantForTeam(
        team: team,
        servantDocId: servant.docID,
        servantData: newServantData,
      );

      final newServantTeamIds = _extractAssignedTeamIds(newServantData);
      if (!newServantTeamIds.contains(team.id)) {
        newServantTeamIds.add(team.id);
      }

      transaction.update(teamRef, {
        'assignedServantId': servant.docID,
        'assignedServantName':
            (newServantData['name'] as String?) ?? servant.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (oldServantRef != null && oldServantId != servant.docID) {
        await _removeTeamFromServant(transaction, oldServantRef, team.id);
      }

      transaction.set(newServantRef, {
        ..._servantAssignmentPatch(newServantTeamIds),
        'groupId': team.groupId,
      }, SetOptions(merge: true));
    });
  }

  /// Remove any responsible servant from [team] and removes this team from that servant's assignment list.
  Future<void> unassignServantFromTeam({
    required AuthUser actor,
    required TeamModel team,
  }) async {
    _assertAdmin(actor);

    final teamRef = _classes.doc(team.id);

    await _firestore.runTransaction((transaction) async {
      final teamSnap = await transaction.get(teamRef);
      if (!teamSnap.exists) {
        throw StateError('Team not found');
      }

      final data = teamSnap.data() ?? <String, dynamic>{};
      final oldServantId = (data['assignedServantId'] as String?)?.trim();
      final oldServantRef = oldServantId == null || oldServantId.isEmpty
          ? null
          : _users.doc(oldServantId);

      transaction.update(teamRef, {
        'assignedServantId': FieldValue.delete(),
        'assignedServantName': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (oldServantRef != null) {
        await _removeTeamFromServant(transaction, oldServantRef, team.id);
      }
    });
  }

  /// Set the exact list of students that belong to [team].
  ///
  /// - Students selected => classId = team.id, team_name = team.name
  /// - Students removed  => classId deleted, team_name cleared
  ///
  /// Also maintains Classes/{teamId}.student_ids array (best-effort).
  Future<void> setStudentsForTeam({
    required AuthUser actor,
    required TeamModel team,
    required List<StudentModel> selectedStudents,
  }) async {
    _assertAdmin(actor);

    // Current team members (server-side).
    final currentSnap = await _students
        .where('classId', isEqualTo: team.id)
        .get();
    final currentIds = currentSnap.docs.map((d) => d.id).toSet();

    final selectedIds = selectedStudents.map((s) => s.docID).toSet();
    final affectedClassIds = <String>{team.id};

    final toAdd = selectedStudents
        .where((s) => !currentIds.contains(s.docID))
        .toList();
    final toRemoveIds = currentIds.difference(selectedIds).toList();

    // We might need uid for user-doc syncing when removing, so fetch those students.
    final toRemoveStudents = <StudentModel>[];
    if (toRemoveIds.isNotEmpty) {
      for (var i = 0; i < toRemoveIds.length; i += 10) {
        final end = (i + 10 > toRemoveIds.length) ? toRemoveIds.length : i + 10;
        final slice = toRemoveIds.sublist(i, end);
        final snap = await _students
            .where(FieldPath.documentId, whereIn: slice)
            .get();
        for (final doc in snap.docs) {
          final data = doc.data();
          toRemoveStudents.add(StudentModel.fromMap(data, doc.id));
        }
      }
    }

    // Build a single atomic batch operation
    // If operations exceed 500, we'll use multiple batches but ALL must succeed
    final batch = _firestore.batch();

    // Add / move to team
    for (final student in toAdd) {
      final previousClassId = student.classId?.trim();
      if (previousClassId != null &&
          previousClassId.isNotEmpty &&
          previousClassId != team.id) {
        affectedClassIds.add(previousClassId);
      }

      final studentRef = _students.doc(student.docID);
      batch.set(studentRef, {
        'classId': team.id,
        'team_name': team.name,
        'group': team.groupId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Keep user doc in sync (best effort).
      if (student.uid.isNotEmpty) {
        batch.set(_users.doc(student.uid), {
          'classId': team.id,
          'team_name': team.name,
          'groupId': team.groupId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    // Remove from team
    for (final student in toRemoveStudents) {
      final previousClassId = student.classId?.trim();
      if (previousClassId != null && previousClassId.isNotEmpty) {
        affectedClassIds.add(previousClassId);
      }

      final studentRef = _students.doc(student.docID);
      batch.set(studentRef, {
        'classId': FieldValue.delete(),
        'team_name': '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (student.uid.isNotEmpty) {
        batch.set(_users.doc(student.uid), {
          'classId': FieldValue.delete(),
          'team_name': '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    // Maintain team student_ids (best-effort)
    batch.set(_classes.doc(team.id), {
      'student_ids': selectedIds.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Commit atomically - all or nothing
    await batch.commit();

    // Recompute student IDs for affected classes (best-effort, non-blocking)
    try {
      await _recomputeStudentIdsForClasses(affectedClassIds);
    } catch (e) {
      // Log but don't fail the main operation
      print('Warning: Failed to recompute student IDs: $e');
    }
  }
}

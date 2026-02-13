import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/constants/firestore_collections.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/servant/data/models/servant_models.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/team/data/models/team_model.dart';

/// Admin-only operations that touch multiple collections.
///
/// Feature: Teams
/// - Admin assigns a servant responsible for a team.
/// - Admin assigns/removes students to/from a team.
///
/// NOTE: Permissions must be enforced by Firestore Security Rules.
class AdminTeamService {
  final FirebaseFirestore _firestore;

  AdminTeamService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

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

    final teamSnap = await teamRef.get();
    if (!teamSnap.exists) {
      throw StateError('Team not found');
    }

    final data = teamSnap.data() ?? <String, dynamic>{};
    final oldServantId = data['assignedServantId'] as String?;
    final oldServantRef = oldServantId == null || oldServantId.isEmpty
        ? null
        : _users.doc(oldServantId);

    List<String> oldServantTeamIds = const [];
    if (oldServantRef != null && oldServantId != servant.docID) {
      final oldServantSnap = await oldServantRef.get();
      oldServantTeamIds = _extractAssignedTeamIds(
        oldServantSnap.data() ?? <String, dynamic>{},
      )..removeWhere((id) => id == team.id);
    }

    final newServantSnap = await newServantRef.get();
    final newServantTeamIds = _extractAssignedTeamIds(
      newServantSnap.data() ?? <String, dynamic>{},
    );
    if (!newServantTeamIds.contains(team.id)) {
      newServantTeamIds.add(team.id);
    }

    final batch = _firestore.batch();

    // Update team assignment.
    batch.update(teamRef, {
      'assignedServantId': servant.docID,
      'assignedServantName': servant.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Remove this team from the previous servant assignment list, if any.
    if (oldServantRef != null && oldServantId != servant.docID) {
      batch.set(
        oldServantRef,
        _servantAssignmentPatch(oldServantTeamIds),
        SetOptions(merge: true),
      );
    }

    // Set the new servant assignment.
    batch.set(newServantRef, {
      ..._servantAssignmentPatch(newServantTeamIds),
      'groupId': team.groupId,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Remove any responsible servant from [team] and removes this team from that servant's assignment list.
  Future<void> unassignServantFromTeam({
    required AuthUser actor,
    required TeamModel team,
  }) async {
    _assertAdmin(actor);

    final teamRef = _classes.doc(team.id);
    final teamSnap = await teamRef.get();
    if (!teamSnap.exists) {
      throw StateError('Team not found');
    }

    final data = teamSnap.data() ?? <String, dynamic>{};
    final oldServantId = data['assignedServantId'] as String?;
    final oldServantRef = oldServantId == null || oldServantId.isEmpty
        ? null
        : _users.doc(oldServantId);

    List<String> oldServantTeamIds = const [];
    if (oldServantRef != null) {
      final oldServantSnap = await oldServantRef.get();
      oldServantTeamIds = _extractAssignedTeamIds(
        oldServantSnap.data() ?? <String, dynamic>{},
      )..removeWhere((id) => id == team.id);
    }

    final batch = _firestore.batch();

    batch.update(teamRef, {
      'assignedServantId': FieldValue.delete(),
      'assignedServantName': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (oldServantRef != null) {
      batch.set(
        oldServantRef,
        _servantAssignmentPatch(oldServantTeamIds),
        SetOptions(merge: true),
      );
    }

    await batch.commit();
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

    final toAdd = selectedStudents
        .where((s) => !currentIds.contains(s.docID))
        .toList();
    final toRemoveIds = currentIds.difference(selectedIds).toList();

    // We might need uid for user-doc syncing when removing, so fetch those students.
    final toRemoveStudents = <StudentModel>[];
    for (final id in toRemoveIds) {
      final snap = await _students.doc(id).get();
      if (snap.exists && snap.data() != null) {
        toRemoveStudents.add(StudentModel.fromMap(snap.data()!, snap.id));
      }
    }

    // Collect batch operations (we will commit them in chunks to avoid the 500 ops limit).
    final ops = <void Function(WriteBatch)>[];

    void addOp(void Function(WriteBatch) op) => ops.add(op);

    // Add / move to team
    for (final student in toAdd) {
      final studentRef = _students.doc(student.docID);
      addOp(
        (b) => b.set(studentRef, {
          'classId': team.id,
          'team_name': team.name,
          'group': team.groupId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      );

      // Keep user doc in sync (best effort).
      if (student.uid.isNotEmpty) {
        addOp(
          (b) => b.set(_users.doc(student.uid), {
            'classId': team.id,
            'team_name': team.name,
            'groupId': team.groupId,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)),
        );
      }
    }

    // Remove from team
    for (final student in toRemoveStudents) {
      final studentRef = _students.doc(student.docID);
      addOp(
        (b) => b.set(studentRef, {
          'classId': FieldValue.delete(),
          'team_name': '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      );

      if (student.uid.isNotEmpty) {
        addOp(
          (b) => b.set(_users.doc(student.uid), {
            'classId': FieldValue.delete(),
            'team_name': '',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)),
        );
      }
    }

    // Maintain team student_ids (best-effort)
    addOp(
      (b) => b.set(_classes.doc(team.id), {
        'student_ids': selectedIds.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );

    // Commit in chunks (<= 400 ops per batch, to be safe).
    for (var i = 0; i < ops.length; i += 400) {
      final batch = _firestore.batch();
      final end = (i + 400 > ops.length) ? ops.length : i + 400;
      final slice = ops.sublist(i, end);
      for (final op in slice) {
        op(batch);
      }
      await batch.commit();
    }
  }
}

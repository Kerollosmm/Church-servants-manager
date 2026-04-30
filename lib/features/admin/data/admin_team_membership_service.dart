import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/core/utils/list_extensions.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminTeamMembershipService {
  AdminTeamMembershipService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _classes =>
      _firestore.collection(FirestoreCollections.classes);
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);
  CollectionReference<Map<String, dynamic>> get _students =>
      _firestore.collection(FirestoreCollections.students);

  DocumentReference<Map<String, dynamic>> _teamRef(String teamId) =>
      _classes.doc(teamId);

  DocumentReference<Map<String, dynamic>> _userRef(String userId) =>
      _users.doc(userId);

  DocumentReference<Map<String, dynamic>> _studentRef(String studentId) =>
      _students.doc(studentId);

  void _assertAdmin(AuthUser actor) {
    if (actor.role != UserRole.admin) {
      throw StateError('Permission denied: admin only');
    }
  }

  Future<void> setStudentsForTeam({
    required AuthUser actor,
    required TeamModel team,
    required List<StudentModel> selectedStudents,
  }) async {
    _assertAdmin(actor);

    final currentIds = await _getCurrentTeamMemberIds(team.id);
    final selectedIds = selectedStudents.map((s) => s.docID).toSet();

    final toAdd = selectedStudents
        .where((s) => !currentIds.contains(s.docID))
        .toList();
    final toRemoveIds = currentIds.difference(selectedIds).toList();
    final toRemoveStudents = await _loadStudentsByIds(toRemoveIds);

    final ops = _buildSetTeamMembersOps(
      team: team,
      toAdd: toAdd,
      toRemove: toRemoveStudents,
      selectedIds: selectedIds.toList(growable: false),
    );

    await _commitOpsInChunks(ops);
  }

  Future<Set<String>> _getCurrentTeamMemberIds(String teamId) async {
    final snapshot = await _students.where('classId', isEqualTo: teamId).get();
    return snapshot.docs
        .where((doc) => doc.data()['isArchived'] != true)
        .map((d) => d.id)
        .toSet();
  }

  Future<List<StudentModel>> _loadStudentsByIds(List<String> ids) async {
    if (ids.isEmpty) return const <StudentModel>[];

    final result = <StudentModel>[];
    final slices = ids.chunk(10);

    const concurrencyLimit = 5;
    for (var i = 0; i < slices.length; i += concurrencyLimit) {
      final end = (i + concurrencyLimit > slices.length)
          ? slices.length
          : i + concurrencyLimit;
      final currentSlices = slices.sublist(i, end);

      final snaps = await Future.wait(
        currentSlices.map(
          (s) => _students.where(FieldPath.documentId, whereIn: s).get(),
        ),
      );

      for (final snap in snaps) {
        for (final doc in snap.docs) {
          final student = StudentModel.fromMap(doc.data(), doc.id);
          if (student.isArchived) continue;
          result.add(student);
        }
      }
    }

    return result;
  }

  List<void Function(WriteBatch)> _buildSetTeamMembersOps({
    required TeamModel team,
    required List<StudentModel> toAdd,
    required List<StudentModel> toRemove,
    required List<String> selectedIds,
  }) {
    final ops = <void Function(WriteBatch)>[];

    void addOp(void Function(WriteBatch) op) => ops.add(op);

    for (final student in toAdd) {
      final previousClassId = student.classId?.trim();
      if (previousClassId != null &&
          previousClassId.isNotEmpty &&
          previousClassId != team.id) {
        addOp(
          (b) => b.set(_teamRef(previousClassId), {
            'student_ids': FieldValue.arrayRemove([student.docID]),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)),
        );
      }

      addOp(
        (b) => b.set(_studentRef(student.docID), {
          'classId': team.id,
          'team_name': team.name,
          'group': team.groupId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      );

      if (student.uid.isNotEmpty) {
        addOp(
          (b) => b.set(_userRef(student.uid), {
            'classId': team.id,
            'team_name': team.name,
            'groupId': team.groupId,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)),
        );
      }
    }

    for (final student in toRemove) {
      addOp(
        (b) => b.set(_studentRef(student.docID), {
          'classId': FieldValue.delete(),
          'team_name': '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      );

      if (student.uid.isNotEmpty) {
        addOp(
          (b) => b.set(_userRef(student.uid), {
            'classId': FieldValue.delete(),
            'team_name': '',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)),
        );
      }
    }

    addOp(
      (b) => b.set(_teamRef(team.id), {
        'student_ids': selectedIds,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );

    return ops;
  }

  Future<void> _commitOpsInChunks(
    List<void Function(WriteBatch)> ops, {
    int chunkSize = 400,
  }) async {
    for (var i = 0; i < ops.length; i += chunkSize) {
      final batch = _firestore.batch();
      final end = (i + chunkSize > ops.length) ? ops.length : i + chunkSize;
      final slice = ops.sublist(i, end);
      for (final op in slice) {
        op(batch);
      }
      await batch.commit();
    }
  }
}

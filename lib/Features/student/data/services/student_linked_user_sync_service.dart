import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/domain/failures/student_failures.dart';

class StudentLinkedUserSyncService {
  StudentLinkedUserSyncService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _studentsCollection =>
      _firestore.collection(FirestoreCollections.students);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestoreCollections.users);

  Map<String, dynamic> buildLinkedUserRolePatch({
    required StudentModel updatedStudent,
    required UserRole previousRole,
  }) {
    final uid = updatedStudent.uid.trim();
    if (uid.isEmpty) {
      throw const GenericStudentFailure(
        'Cannot change role for student without linked user account.',
      );
    }

    final payload = <String, dynamic>{
      'uid': uid,
      'role': updatedStudent.role.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (updatedStudent.role == UserRole.servant) {
      payload['groupId'] = updatedStudent.group.name;
      final classId = updatedStudent.classId?.trim() ?? '';
      if (classId.isNotEmpty) {
        payload['assignedTeamId'] = classId;
        payload['assignedTeamIds'] = [classId];
      } else {
        payload['assignedTeamId'] = FieldValue.delete();
        payload['assignedTeamIds'] = FieldValue.delete();
      }
    } else if (updatedStudent.role == UserRole.student ||
        previousRole == UserRole.servant) {
      payload['groupId'] = FieldValue.delete();
      payload['assignedTeamId'] = FieldValue.delete();
      payload['assignedTeamIds'] = FieldValue.delete();
    }

    return payload;
  }

  Future<void> syncLinkedUserRoleFromStudent({
    required StudentModel updatedStudent,
    required UserRole previousRole,
  }) async {
    try {
      final uid = updatedStudent.uid.trim();
      final payload = buildLinkedUserRolePatch(
        updatedStudent: updatedStudent,
        previousRole: previousRole,
      );
      await _usersCollection.doc(uid).set(payload, SetOptions(merge: true));
    } catch (e) {
      if (e is StudentFailure) rethrow;
      throw mapExceptionToStudentFailure(e);
    }
  }

  Future<void> updateStudentAndSyncLinkedUserRole({
    required StudentModel updatedStudent,
    required UserRole previousRole,
  }) async {
    try {
      if (updatedStudent.role == previousRole) {
        await _studentsCollection
            .doc(updatedStudent.docID)
            .update(updatedStudent.toMap());
        return;
      }

      final uid = updatedStudent.uid.trim();
      final linkedUserPatch = buildLinkedUserRolePatch(
        updatedStudent: updatedStudent,
        previousRole: previousRole,
      );

      final batch = _firestore.batch();
      batch.update(
        _studentsCollection.doc(updatedStudent.docID),
        updatedStudent.toMap(),
      );
      batch.set(
        _usersCollection.doc(uid),
        linkedUserPatch,
        SetOptions(merge: true),
      );
      await batch.commit();
    } catch (e) {
      if (e is StudentFailure) rethrow;
      throw mapExceptionToStudentFailure(e);
    }
  }
}

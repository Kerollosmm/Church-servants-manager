import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/domain/failures/student_failures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentLinkedUserSyncService {
  StudentLinkedUserSyncService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _studentsCollection =>
      _firestore.collection(FirestoreCollections.students);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestoreCollections.servants);

  Map<String, dynamic> buildLinkedUserRolePatch({
    required StudentModel updatedStudent,
    required UserRole previousRole,
    String? updatedEmail,
  }) {
    final uid = updatedStudent.uid.trim();
    if (uid.isEmpty) {
      throw const GenericStudentFailure(
        'Cannot sync student profile without linked user account.',
      );
    }

    final payload = <String, dynamic>{
      'uid': uid,
      'name': updatedStudent.name,
      'role': updatedStudent.role.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final normalizedEmail = updatedEmail?.trim();
    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      payload['email'] = normalizedEmail;
    }

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
    String? updatedEmail,
  }) async {
    try {
      final uid = updatedStudent.uid.trim();
      final payload = buildLinkedUserRolePatch(
        updatedStudent: updatedStudent,
        previousRole: previousRole,
        updatedEmail: updatedEmail,
      );
      await _usersCollection.doc(uid).set(payload, SetOptions(merge: true));
    } on StudentFailure {
      rethrow;
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  Future<void> updateStudentAndSyncLinkedUserRole({
    required StudentModel updatedStudent,
    required UserRole previousRole,
    String? updatedEmail,
  }) async {
    try {
      final uid = updatedStudent.uid.trim();
      if (uid.isEmpty) {
        await _studentsCollection
            .doc(updatedStudent.docID)
            .update(updatedStudent.toMap());
        return;
      }

      final linkedUserPatch = buildLinkedUserRolePatch(
        updatedStudent: updatedStudent,
        previousRole: previousRole,
        updatedEmail: updatedEmail,
      );

      final batch = _firestore.batch()
        ..update(
          _studentsCollection.doc(updatedStudent.docID),
          updatedStudent.toMap(),
        )
        ..set(
          _usersCollection.doc(uid),
          linkedUserPatch,
          SetOptions(merge: true),
        );
      await batch.commit();
    } on StudentFailure {
      rethrow;
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/constants/firestore_collections.dart';
import 'package:church_managment_system/features/student/domain/failures/student_failures.dart';
import 'package:church_managment_system/features/student/domain/repos/i_student_repository.dart';
import 'package:rxdart/rxdart.dart';
import '../models/student_model.dart';

class StudentDataRepository implements IStudentRepository {
  final FirebaseFirestore _firestore;

  StudentDataRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _studentsCollection =>
      _firestore.collection(FirestoreCollections.students);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestoreCollections.users);

  List<StudentModel> _mapStudentDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs
        .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
        .toList(growable: false);
  }

  Query<Map<String, dynamic>> _studentsByClassQuery(String classId) {
    return _studentsCollection.where('classId', isEqualTo: classId);
  }

  Query<Map<String, dynamic>> _studentsByGroupQuery(String groupName) {
    return _studentsCollection.where('group', isEqualTo: groupName);
  }

  Future<List<StudentModel>> _tryGetStudentsByClassFromCache(
    String classId,
  ) async {
    try {
      final cacheSnapshot = await _studentsByClassQuery(
        classId,
      ).get(const GetOptions(source: Source.cache));
      if (cacheSnapshot.docs.isNotEmpty) {
        return _mapStudentDocs(cacheSnapshot.docs);
      }
    } catch (_) {}
    return const <StudentModel>[];
  }

  Future<List<StudentModel>> _getStudentsByClassFromServer(
    String classId,
  ) async {
    final snapshot = await _studentsByClassQuery(
      classId,
    ).get(const GetOptions(source: Source.server));
    return _mapStudentDocs(snapshot.docs);
  }

  Future<List<String>> _getStudentIdsFromClassDocument(String classId) async {
    final classDoc = await _firestore
        .collection(FirestoreCollections.classes)
        .doc(classId)
        .get();
    if (!classDoc.exists) return const <String>[];
    return List<String>.from(
      classDoc.data()?['student_ids'] ?? const <String>[],
    );
  }

  Future<List<StudentModel>> _getStudentsByDocumentIds(
    List<String> studentIds,
  ) async {
    if (studentIds.isEmpty) return const <StudentModel>[];
    final chunks = _chunkList(studentIds, 10);

    final futures = chunks.map(
      (chunk) =>
          _studentsCollection.where(FieldPath.documentId, whereIn: chunk).get(),
    );

    final results = await Future.wait(futures);
    return results
        .expand((snap) => snap.docs)
        .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
        .toList(growable: false);
  }

  Map<String, dynamic> _buildLinkedUserRolePatch({
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
      final payload = _buildLinkedUserRolePatch(
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
      final linkedUserPatch = _buildLinkedUserRolePatch(
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

  @override
  Future<StudentModel?> getStudentById(String docId) async {
    try {
      final doc = await _studentsCollection.doc(docId).get();
      if (doc.exists && doc.data() != null) {
        return StudentModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<StudentModel?> getStudentByUid(String uid) async {
    try {
      final snapshot = await _studentsCollection
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return StudentModel.fromMap(doc.data(), doc.id);
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<List<StudentModel>> getAllStudents({
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    Query<Map<String, dynamic>> query = _studentsCollection
        .orderBy('name')
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    try {
      final cacheSnapshot = await query.get(
        const GetOptions(source: Source.cache),
      );
      if (cacheSnapshot.docs.isNotEmpty) {
        return _mapStudentDocs(cacheSnapshot.docs);
      }
    } catch (_) {
      // Ignore cache errors and fallback to server
    }

    try {
      final serverSnapshot = await query.get(
        const GetOptions(source: Source.server),
      );
      return _mapStudentDocs(serverSnapshot.docs);
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<List<StudentModel>> getStudentsByClass(String classId) async {
    try {
      final cacheStudents = await _tryGetStudentsByClassFromCache(classId);
      if (cacheStudents.isNotEmpty) {
        return cacheStudents;
      }

      // Primary approach: Single query using classId field (most efficient)
      final serverStudents = await _getStudentsByClassFromServer(classId);
      if (serverStudents.isNotEmpty) {
        return serverStudents;
      }

      // If classId field not populated, use whereIn with concurrent chunking
      final studentIds = await _getStudentIdsFromClassDocument(classId);
      return _getStudentsByDocumentIds(studentIds);
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  /// Splits a list into chunks of specified size.
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      final end = (i + chunkSize < list.length) ? i + chunkSize : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }

  @override
  Future<List<StudentModel>> getStudentsByGrade(int grade) async {
    try {
      final snapshot = await _studentsCollection
          .where('grade', isEqualTo: grade)
          .get();

      return _mapStudentDocs(snapshot.docs);
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<List<StudentModel>> getStudentsByGroup(String groupName) async {
    try {
      final snapshot = await _studentsByGroupQuery(groupName).get();

      return _mapStudentDocs(snapshot.docs);
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  Future<({List<StudentModel> students, bool isFromCache})>
  getStudentsByGroupWithFallback(String groupName) async {
    try {
      final cacheSnapshot = await _studentsCollection
          .where('group', isEqualTo: groupName)
          .get(const GetOptions(source: Source.cache));
      if (cacheSnapshot.docs.isNotEmpty) {
        return (
          students: _mapStudentDocs(cacheSnapshot.docs),
          isFromCache: true,
        );
      }
    } catch (_) {}

    try {
      final serverSnapshot = await _studentsByGroupQuery(
        groupName,
      ).get(const GetOptions(source: Source.server));
      return (
        students: _mapStudentDocs(serverSnapshot.docs),
        isFromCache: false,
      );
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<List<StudentModel>> searchStudents(
    String query, {
    int limit = 20,
  }) async {
    // In-memory, case-insensitive search is handled by StudentDataBloc.
    // This repo method now simply fetches all students for the BLoC to filter.
    return getAllStudents(limit: limit);
  }

  @override
  Future<String> createStudent(StudentModel student) async {
    try {
      final docRef = student.docID.isNotEmpty
          ? _studentsCollection.doc(student.docID)
          : _studentsCollection.doc();
      final finalStudent = student.copyWith(docID: docRef.id);
      await docRef.set(finalStudent.toMap());
      return docRef.id;
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<void> updateStudent(StudentModel student) async {
    try {
      final docRef = _studentsCollection.doc(student.docID);
      await docRef.update(student.toMap());
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<void> upsertStudent(StudentModel student) async {
    try {
      final docRef = _studentsCollection.doc(student.docID);
      await docRef.set(student.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<void> deleteStudent(String docId) async {
    try {
      // Note: We are not deleting the associated User record here automatically
      // as that might delete a valid user account. We just delete the student profile.
      await _studentsCollection.doc(docId).delete();
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  /// Helper to get student IDs for given class IDs (batch query)
  Future<List<String>> getStudentIdsByClasses(List<String> classIds) async {
    if (classIds.isEmpty) return [];

    final studentIds = <String>[];
    final chunks = _chunkList(classIds, 10);

    // Parallel execution
    final futures = chunks.map(
      (chunk) => _firestore
          .collection(FirestoreCollections.classes)
          .where(FieldPath.documentId, whereIn: chunk)
          .get(),
    );

    final results = await Future.wait(futures);

    for (final snapshot in results) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final ids = List<String>.from(data['student_ids'] ?? []);
        studentIds.addAll(ids);
      }
    }

    return studentIds;
  }

  // Stream-based queries (real-time)

  @override
  Stream<List<StudentModel>> watchAllStudents() {
    return _studentsCollection
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Stream<List<StudentModel>> watchStudentsByClass(String classId) {
    return _studentsCollection
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Stream<List<StudentModel>> watchStudentsByClasses(List<String> classIds) {
    final normalizedIds = <String>{};
    for (final classId in classIds) {
      final trimmed = classId.trim();
      if (trimmed.isNotEmpty) {
        normalizedIds.add(trimmed);
      }
    }

    if (normalizedIds.isEmpty) {
      return Stream.value(const <StudentModel>[]);
    }

    final chunks = _chunkList(normalizedIds.toList(growable: false), 10);
    final streams = chunks
        .map(
          (chunk) => _studentsCollection
              .where('classId', whereIn: chunk)
              .snapshots()
              .map(
                (snapshot) => snapshot.docs
                    .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
                    .toList(),
              ),
        )
        .toList(growable: false);

    if (streams.length == 1) {
      return streams.first;
    }

    return Rx.combineLatestList(streams).map((chunkResults) {
      final byDocId = <String, StudentModel>{};
      for (final students in chunkResults) {
        for (final student in students) {
          byDocId[student.docID] = student;
        }
      }
      // Ordering is handled in StudentDataBloc before emitting UI state.
      return byDocId.values.toList(growable: false);
    });
  }

  @override
  Stream<List<StudentModel>> watchStudentsByGroup(String groupName) {
    return _studentsCollection
        .where('group', isEqualTo: groupName)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}

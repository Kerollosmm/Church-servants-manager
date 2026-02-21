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

  Future<void> syncLinkedUserRoleFromStudent({
    required StudentModel updatedStudent,
    required UserRole previousRole,
  }) async {
    try {
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

      await _usersCollection.doc(uid).set(payload, SetOptions(merge: true));
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
    try {
      Query<Map<String, dynamic>> query = _studentsCollection
          .orderBy('name')
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<List<StudentModel>> getStudentsByClass(String classId) async {
    try {
      // Primary approach: Single query using classId field (most efficient)
      final snapshot = await _studentsCollection
          .where('classId', isEqualTo: classId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
            .toList();
      }

      // If classId field not populated, use whereIn with concurrent chunking
      final classDoc = await _firestore
          .collection(FirestoreCollections.classes)
          .doc(classId)
          .get();
      if (!classDoc.exists) return [];

      final studentIds = List<String>.from(
        classDoc.data()?['student_ids'] ?? [],
      );
      if (studentIds.isEmpty) return [];

      final chunks = _chunkList(studentIds, 10);

      final futures = chunks.map(
        (chunk) => _studentsCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get(),
      );

      final results = await Future.wait(futures);

      return results
          .expand((snap) => snap.docs)
          .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
          .toList();
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

      return snapshot.docs
          .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<List<StudentModel>> getStudentsByGroup(String groupName) async {
    try {
      final snapshot = await _studentsCollection
          .where('group', isEqualTo: groupName)
          .get();

      return snapshot.docs
          .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  Future<({List<StudentModel> students, bool isFromCache})>
  getStudentsByGroupWithFallback(String groupName) async {
    try {
      final serverSnapshot = await _studentsCollection
          .where('group', isEqualTo: groupName)
          .get(const GetOptions(source: Source.server));
      return (
        students: serverSnapshot.docs
            .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
            .toList(growable: false),
        isFromCache: false,
      );
    } catch (_) {
      try {
        final cacheSnapshot = await _studentsCollection
            .where('group', isEqualTo: groupName)
            .get(const GetOptions(source: Source.cache));
        return (
          students: cacheSnapshot.docs
              .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
              .toList(growable: false),
          isFromCache: true,
        );
      } catch (e) {
        throw mapExceptionToStudentFailure(e);
      }
    }
  }

  @override
  Future<List<StudentModel>> searchStudents(
    String query, {
    int limit = 20,
  }) async {
    try {
      if (query.isEmpty) return getAllStudents(limit: limit);

      final snapshot = await _studentsCollection
          .orderBy('name')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<String> createStudent(StudentModel student) async {
    try {
      final docRef = _studentsCollection.doc();
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

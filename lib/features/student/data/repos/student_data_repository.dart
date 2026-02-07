import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church_managment_system/core/constants/firestore_collections.dart';
import 'package:church_managment_system/features/student/domain/failures/student_failures.dart';
import 'package:church_managment_system/features/student/domain/repos/i_student_repository.dart';
import '../models/student_model.dart';

class StudentDataRepository implements IStudentRepository {
  final FirebaseFirestore _firestore;

  StudentDataRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _studentsCollection =>
      _firestore.collection(FirestoreCollections.students);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestoreCollections.users);

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

      // Fallback: If classId field not populated, use whereIn with concurrent chunking
      final classDoc = await _firestore
          .collection(FirestoreCollections.classes)
          .doc(classId)
          .get();
      if (!classDoc.exists) return [];

      final studentIds = List<String>.from(
        classDoc.data()?['student_ids'] ?? [],
      );
      if (studentIds.isEmpty) return [];

      // Firestore whereIn limit is 30 in this context (actually 10 for OR, 30 for IN sometimes, sticking to 30 as optimized default)
      // Actually Firestore whereIn 'IN' limit is 10. Let's verify.
      // Wait, standard IN limit is 10. we should stick to 10 to be safe, but run in parallel.
      // Correction: Firestore 'in' operator supports up to 10 comparison values.
      // However, we can run multiple futures in parallel.

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
      final batch = _firestore.batch();

      // 1. Create Student Document
      final docRef = _studentsCollection.doc();
      final finalStudent = student.copyWith(docID: docRef.id);
      batch.set(docRef, finalStudent.toMap());

      // 2. Dual-Write: Ensure User record is consistent if UID exists
      if (student.uid.isNotEmpty) {
        final userRef = _usersCollection.doc(student.uid);
        // Merging to avoid overwriting auth data if it exists,
        // but enforcing role and name sync.
        batch.set(userRef, {
          'role': 'student', // Enforce role
          'name': student.name, // Sync name
          'studentProfileId': docRef.id, // Link back
          'classId': student.classId,
          'grade': student.grade,
        }, SetOptions(merge: true));
      }

      await batch.commit();
      return docRef.id;
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<void> updateStudent(StudentModel student) async {
    try {
      final batch = _firestore.batch();

      // 1. Update Student Document
      final docRef = _studentsCollection.doc(student.docID);
      batch.update(docRef, student.toMap());

      // 2. Dual-Write: Sync changes to User record if UID exists
      if (student.uid.isNotEmpty) {
        final userRef = _usersCollection.doc(student.uid);
        batch.set(userRef, {
          'name': student.name,
          'classId': student.classId,
          'grade': student.grade,
        }, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<void> upsertStudent(StudentModel student) async {
    try {
      final batch = _firestore.batch();

      // 1. Upsert Student Document
      final docRef = _studentsCollection.doc(student.docID);
      batch.set(docRef, student.toMap(), SetOptions(merge: true));

      // 2. Dual-Write: Sync to User record
      if (student.uid.isNotEmpty) {
        final userRef = _usersCollection.doc(student.uid);
        batch.set(userRef, {
          'name': student.name,
          'classId': student.classId,
          'grade': student.grade,
          'role': 'student', // Ensure role if creating/repairing
          'studentProfileId':
              student.docID, // Ensure link if creating/repairing
        }, SetOptions(merge: true));
      }

      await batch.commit();
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
}

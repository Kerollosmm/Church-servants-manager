import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church_managment_system/core/constants/firestore_collections.dart';
import '../models/student_model.dart';

class StudentDataRepository {
  final FirebaseFirestore _firestore;

  StudentDataRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _studentsCollection =>
      _firestore.collection(FirestoreCollections.students);

  /// Get a single student by document ID
  Future<StudentModel?> getStudentById(String docId) async {
    try {
      final doc = await _studentsCollection.doc(docId).get();
      if (doc.exists && doc.data() != null) {
        return StudentModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch student: $e');
    }
  }

  /// Get a student by Firebase Auth UID (or app UID).
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
      throw Exception('Failed to fetch student by uid: $e');
    }
  }

  /// Get all students with pagination support.
  /// [limit] - Maximum number of students to fetch (default: 10).
  /// [lastDocument] - Last document snapshot for cursor-based pagination.
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
      throw Exception('Failed to fetch students: $e');
    }
  }

  /// Get students by class ID using efficient single query.
  /// CRITICAL FIX: Uses classId field instead of N+1 loop.
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

      // Fallback: If classId field not populated, use whereIn with chunking
      final classDoc = await _firestore
          .collection(FirestoreCollections.classes)
          .doc(classId)
          .get();
      if (!classDoc.exists) return [];

      final studentIds = List<String>.from(
        classDoc.data()?['student_ids'] ?? [],
      );
      if (studentIds.isEmpty) return [];

      // Firestore whereIn limit is 10, so chunk the IDs
      final students = <StudentModel>[];
      final chunks = _chunkList(studentIds, 10);

      for (final chunk in chunks) {
        final chunkSnapshot = await _studentsCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in chunkSnapshot.docs) {
          students.add(StudentModel.fromMap(doc.data(), doc.id));
        }
      }

      return students;
    } catch (e) {
      throw Exception('Failed to fetch students by class: $e');
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

  /// Get students by grade
  Future<List<StudentModel>> getStudentsByGrade(int grade) async {
    try {
      final snapshot = await _studentsCollection
          .where('grade', isEqualTo: grade)
          .get();

      return snapshot.docs
          .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch students by grade: $e');
    }
  }

  /// Get students by group (Server-side filtering)
  Future<List<StudentModel>> getStudentsByGroup(String groupName) async {
    try {
      final snapshot = await _studentsCollection
          .where('group', isEqualTo: groupName)
          .get();

      return snapshot.docs
          .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch students by group: $e');
    }
  }

  /// Get student IDs for given class IDs (batch query)
  Future<List<String>> getStudentIdsByClasses(List<String> classIds) async {
    if (classIds.isEmpty) return [];

    final studentIds = <String>[];
    final chunks = _chunkList(classIds, 10);

    for (final chunk in chunks) {
      final snapshot = await _firestore
          .collection(FirestoreCollections.classes)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final ids = List<String>.from(data['student_ids'] ?? []);
        studentIds.addAll(ids);
      }
    }

    return studentIds;
  }

  /// Search students by name (case-insensitive prefix search)
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
      throw Exception('Failed to search students: $e');
    }
  }

  /// Create a new student
  Future<String> createStudent(StudentModel student) async {
    try {
      final docRef = _studentsCollection.doc();
      final data = student.copyWith(docID: docRef.id).toMap();
      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create student: $e');
    }
  }

  /// Upsert a student document (merge).
  Future<void> upsertStudent(StudentModel student) async {
    try {
      await _studentsCollection.doc(student.docID).set(
            student.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Failed to upsert student: $e');
    }
  }

  /// Update an existing student
  Future<void> updateStudent(StudentModel student) async {
    try {
      final data = student.toMap();
      await _studentsCollection.doc(student.docID).update(data);
    } catch (e) {
      throw Exception('Failed to update student: $e');
    }
  }

  /// Update specific fields of a student
  Future<void> updateStudentFields(
    String docId,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _studentsCollection.doc(docId).update(fields);
    } catch (e) {
      throw Exception('Failed to update student fields: $e');
    }
  }

  /// Delete a student by document ID
  Future<void> deleteStudent(String docId) async {
    try {
      await _studentsCollection.doc(docId).delete();
    } catch (e) {
      throw Exception('Failed to delete student: $e');
    }
  }
}

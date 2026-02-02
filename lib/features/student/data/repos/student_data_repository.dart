import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';

class StudentDataRepository {
  final FirebaseFirestore _firestore;

  StudentDataRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('Users');

  /// Get a single student by document ID
  Future<StudentModel?> getStudentById(String docId) async {
    try {
      final doc = await _usersCollection.doc(docId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['role'] == 'student') {
          return StudentModel.fromMap(data, doc.id);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch student: $e');
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
      Query<Map<String, dynamic>> query = _usersCollection
          .where('role', isEqualTo: 'student')
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
      final snapshot = await _usersCollection
          .where('classId', isEqualTo: classId)
          .where('role', isEqualTo: 'student')
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
            .toList();
      }

      // Fallback: If classId field not populated, use whereIn with chunking
      final classDoc = await _firestore
          .collection('Classes')
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
        final chunkSnapshot = await _usersCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in chunkSnapshot.docs) {
          final data = doc.data();
          if (data['role'] == 'student') {
            students.add(StudentModel.fromMap(data, doc.id));
          }
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
      final snapshot = await _usersCollection
          .where('role', isEqualTo: 'student')
          .where('grade', isEqualTo: grade)
          .get();

      return snapshot.docs
          .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch students by grade: $e');
    }
  }

  /// Get student IDs for given class IDs (batch query)
  Future<List<String>> getStudentIdsByClasses(List<String> classIds) async {
    if (classIds.isEmpty) return [];

    final studentIds = <String>[];
    final chunks = _chunkList(classIds, 10);

    for (final chunk in chunks) {
      final snapshot = await _firestore
          .collection('Classes')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in snapshot.docs) {
        final ids = List<String>.from(doc.data()['student_ids'] ?? []);
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

      final snapshot = await _usersCollection
          .where('role', isEqualTo: 'student')
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
      final data = student.toMap();
      data['role'] = 'student'; // Ensure role is set
      final docRef = await _usersCollection.add(data);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create student: $e');
    }
  }

  /// Update an existing student
  Future<void> updateStudent(StudentModel student) async {
    try {
      final data = student.toMap();
      await _usersCollection.doc(student.docID).update(data);
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
      await _usersCollection.doc(docId).update(fields);
    } catch (e) {
      throw Exception('Failed to update student fields: $e');
    }
  }

  /// Delete a student by document ID
  Future<void> deleteStudent(String docId) async {
    try {
      await _usersCollection.doc(docId).delete();
    } catch (e) {
      throw Exception('Failed to delete student: $e');
    }
  }
}

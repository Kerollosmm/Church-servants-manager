import 'dart:developer' as developer;
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/core/utils/list_extensions.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/domain/failures/student_failures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

typedef StudentQueryDoc = QueryDocumentSnapshot<Map<String, dynamic>>;

class StudentQueryService {
  StudentQueryService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _studentsCollection =>
      _firestore.collection(FirestoreCollections.students);

  ({List<StudentModel> students, List<String> skippedDocIds}) mapStudentDocs(
    List<StudentQueryDoc> docs,
  ) {
    final students = <StudentModel>[];
    final skippedDocIds = <String>[];
    for (final doc in docs) {
      try {
        students.add(StudentModel.fromMap(doc.data(), doc.id));
      } catch (e) {
        skippedDocIds.add(doc.id);
        developer.log(
          'skipped malformed student doc ${doc.id}',
          error: e,
          name: 'StudentQueryService',
        );
      }
    }
    return (students: students, skippedDocIds: skippedDocIds);
  }

  List<StudentModel> _applyArchivedFilter(
    List<StudentModel> students,
    bool includeArchived,
  ) {
    if (includeArchived) {
      return students;
    }
    return students
        .where((student) => !student.isArchived)
        .toList(growable: false);
  }

  Query<Map<String, dynamic>> _studentsByGroupQuery(String groupName) {
    return _studentsCollection
        .where('group', isEqualTo: groupName)
        .where('isArchived', isEqualTo: false);
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
    final chunks = studentIds.chunk(10);
    final futures = chunks.map(
      (chunk) =>
          _studentsCollection.where(FieldPath.documentId, whereIn: chunk).get(),
    );

    final results = await Future.wait(futures);
    final docs = results.expand((snap) => snap.docs).toList(growable: false);
    return mapStudentDocs(docs).students;
  }

  Future<StudentModel?> getStudentById(
    String docId, {
    bool includeArchived = false,
  }) async {
    try {
      final doc = await _studentsCollection.doc(docId).get();
      if (doc.exists && doc.data() != null) {
        final student = StudentModel.fromMap(doc.data()!, doc.id);
        if (!includeArchived && student.isArchived) {
          return null;
        }
        return student;
      }
      return null;
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  Future<StudentModel?> getStudentByUid(
    String uid, {
    bool includeArchived = false,
  }) async {
    try {
      final snapshot = await _studentsCollection
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      final student = StudentModel.fromMap(doc.data(), doc.id);
      if (!includeArchived && student.isArchived) {
        return null;
      }
      return student;
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  Future<List<StudentModel>> getAllStudents({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    bool includeArchived = false,
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
        return _applyArchivedFilter(
          mapStudentDocs(cacheSnapshot.docs).students,
          includeArchived,
        );
      }
    } catch (e) {
      developer.log('Cache read failed', error: e, name: 'StudentQueryService');
    }

    try {
      final serverSnapshot = await query.get(
        const GetOptions(source: Source.server),
      );
      return _applyArchivedFilter(
        mapStudentDocs(serverSnapshot.docs).students,
        includeArchived,
      );
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  Future<List<StudentModel>> getStudentsByClass(
    String classId, {
    bool includeArchived = false,
  }) async {
    try {
      try {
        Query<Map<String, dynamic>> serverQuery = _studentsCollection.where(
          'classId',
          isEqualTo: classId,
        );
        if (!includeArchived) {
          serverQuery = serverQuery.where('isArchived', isEqualTo: false);
        }
        final serverSnapshot = await serverQuery.get(
          const GetOptions(source: Source.server),
        );
        return mapStudentDocs(serverSnapshot.docs).students;
      } on FirebaseException catch (e) {
        if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
          final studentIds = await _getStudentIdsFromClassDocument(classId);
          return _applyArchivedFilter(
            await _getStudentsByDocumentIds(studentIds),
            includeArchived,
          );
        }
        rethrow;
      }
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  Future<List<StudentModel>> getStudentsByGrade(
    int grade, {
    bool includeArchived = false,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _studentsCollection.where(
        'grade',
        isEqualTo: grade,
      );
      if (!includeArchived) {
        query = query.where('isArchived', isEqualTo: false);
      }

      if (!includeArchived) {
        try {
          final cacheSnapshot = await query.get(
            const GetOptions(source: Source.cache),
          );
          if (cacheSnapshot.docs.isNotEmpty) {
            return mapStudentDocs(cacheSnapshot.docs).students;
          }
        } catch (e) {
          developer.log(
            'Cache read failed',
            error: e,
            name: 'StudentQueryService',
          );
        }
      } else {
        try {
          final cacheSnapshot = await _studentsCollection
              .where('grade', isEqualTo: grade)
              .get(const GetOptions(source: Source.cache));
          if (cacheSnapshot.docs.isNotEmpty) {
            return mapStudentDocs(cacheSnapshot.docs).students;
          }
        } catch (e) {
          developer.log(
            'Cache read failed',
            error: e,
            name: 'StudentQueryService',
          );
        }
      }

      final snapshot = await query.get(const GetOptions(source: Source.server));
      return mapStudentDocs(snapshot.docs).students;
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  Future<List<StudentModel>> getStudentsByGroup(
    String groupName, {
    bool includeArchived = false,
  }) async {
    try {
      final cacheQuery = _studentsCollection.where(
        'group',
        isEqualTo: groupName,
      );
      final fullCacheQuery = cacheQuery;
      final filteredCacheQuery = includeArchived
          ? fullCacheQuery
          : cacheQuery.where('isArchived', isEqualTo: false);

      if (!includeArchived) {
        try {
          final cacheSnapshot = await filteredCacheQuery.get(
            const GetOptions(source: Source.cache),
          );
          if (cacheSnapshot.docs.isNotEmpty) {
            return mapStudentDocs(cacheSnapshot.docs).students;
          }
        } catch (e) {
          developer.log(
            'Cache read failed',
            error: e,
            name: 'StudentQueryService',
          );
        }
      } else {
        try {
          final cacheSnapshot = await fullCacheQuery.get(
            const GetOptions(source: Source.cache),
          );
          if (cacheSnapshot.docs.isNotEmpty) {
            return mapStudentDocs(cacheSnapshot.docs).students;
          }
        } catch (e) {
          developer.log(
            'Cache read failed',
            error: e,
            name: 'StudentQueryService',
          );
        }
      }

      Query<Map<String, dynamic>> query = _studentsCollection.where(
        'group',
        isEqualTo: groupName,
      );
      if (!includeArchived) {
        query = query.where('isArchived', isEqualTo: false);
      }
      final snapshot = await query.get(const GetOptions(source: Source.server));
      return mapStudentDocs(snapshot.docs).students;
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  Future<({List<StudentModel> students, bool isFromCache})>
  getStudentsByGroupWithFallback(
    String groupName, {
    bool includeArchived = false,
  }) async {
    try {
      final cacheSnapshot = await _studentsCollection
          .where('group', isEqualTo: groupName)
          .get(const GetOptions(source: Source.cache));
      if (cacheSnapshot.docs.isNotEmpty) {
        return (
          students: _applyArchivedFilter(
            mapStudentDocs(cacheSnapshot.docs).students,
            includeArchived,
          ),
          isFromCache: true,
        );
      }
    } catch (e) {
      developer.log('Cache read failed', error: e, name: 'StudentQueryService');
    }

    try {
      final serverSnapshot = await _studentsByGroupQuery(
        groupName,
      ).get(const GetOptions(source: Source.server));
      return (
        students: _applyArchivedFilter(
          mapStudentDocs(serverSnapshot.docs).students,
          includeArchived,
        ),
        isFromCache: false,
      );
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  Future<List<StudentModel>> getStudentsByClassesList(
    List<String> classIds, {
    bool includeArchived = false,
  }) async {
    final studentIds = await getStudentIdsByClasses(classIds);
    return _applyArchivedFilter(
      await _getStudentsByDocumentIds(studentIds),
      includeArchived,
    );
  }

  Future<List<String>> getStudentIdsByClasses(List<String> classIds) async {
    if (classIds.isEmpty) return [];

    final studentIds = <String>[];
    final chunks = classIds.chunk(30);
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

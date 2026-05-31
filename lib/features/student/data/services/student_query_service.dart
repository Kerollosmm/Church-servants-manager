import 'dart:async';
import 'dart:developer' as developer;
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/core/services/cache_tracker.dart';
import 'package:church_management_system/core/utils/list_extensions.dart';
import 'package:church_management_system/features/student/data/datasources/student_local_datasource.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/domain/failures/student_failures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentQueryService {
  final FirebaseFirestore _firestore;
  final StudentLocalDatasource _localDatasource;

  StudentQueryService({
    required FirebaseFirestore firestore,
    StudentLocalDatasource? localDatasource,
  }) : _firestore = firestore,
       _localDatasource = localDatasource ?? StudentLocalDatasource();

  CollectionReference<Map<String, dynamic>> get _studentsCollection =>
      _firestore.collection(FirestoreCollections.students);

  Future<DocumentSnapshot<Map<String, dynamic>>> _cachedGet(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      final cached = await ref.get(const GetOptions(source: Source.cache));
      if (cached.exists) return cached;
    } catch (e, stack) {
      developer.log('Cache read error', error: e, stackTrace: stack);
    }
    return ref.get(const GetOptions(source: Source.server));
  }

  Future<StudentModel?> getStudentByUid(
    String uid, {
    bool includeArchived = false,
  }) async {
    try {
      // For UID, which might not be docID, we might have to query firestore or cache.
      // We can scan cache first since it's locally fast
      final allStudents = await _localDatasource.getAllStudents();
      final cached = allStudents.where((s) => s.uid == uid).firstOrNull;
      if (cached != null) {
        if (!includeArchived && cached.isArchived) return null;
        return cached;
      }

      final snapshot = await _studentsCollection
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get(const GetOptions());
      if (snapshot.docs.isEmpty) return null;
      final student = StudentModel.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );

      await _localDatasource.saveStudent(student);

      if (!includeArchived && student.isArchived) return null;
      return student;
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  Future<List<StudentModel>> getAllStudents({
    int limit = 30,
    DocumentSnapshot? lastDocument,
    bool includeArchived = false,
  }) async {
    try {
      if (lastDocument == null) {
        final cached = await _localDatasource.getAllStudents(
          includeArchived: includeArchived,
        );
        if (cached.isNotEmpty) {
          cached.sort((a, b) => a.name.compareTo(b.name));

          final cacheKey = 'students_all_${includeArchived}_$limit';
          if (CacheTracker.shouldRevalidate(cacheKey)) {
            var query = _studentsCollection.orderBy('name').limit(limit);
            if (!includeArchived) {
              query = query.where('isArchived', isEqualTo: false);
            }
            unawaited(
              query
                  .get(const GetOptions(source: Source.server))
                  .then((snapshot) {
                    final result = mapStudentDocs(snapshot.docs).students;
                    if (result.isNotEmpty) {
                      _localDatasource.saveStudents(result);
                      CacheTracker.markFetched(cacheKey);
                    }
                  })
                  .catchError((_) {}),
            );
          }

          return cached;
        }
      }

      var query = _studentsCollection.orderBy('name').limit(limit);
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      if (!includeArchived) {
        query = query.where('isArchived', isEqualTo: false);
      }
      final snapshot = await query.get();
      final result = mapStudentDocs(snapshot.docs).students;

      if (lastDocument == null && result.isNotEmpty) {
        await _localDatasource.saveStudents(result);
      }
      return result;
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  Future<List<StudentModel>> getStudentsByClass(
    String classId, {
    bool includeArchived = false,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      if (startAfter == null) {
        final cached = await _localDatasource.getStudentsByClass(
          classId,
          includeArchived: includeArchived,
        );
        if (cached.isNotEmpty) {
          final cacheKey = 'students_class_${classId}_$includeArchived';
          if (CacheTracker.shouldRevalidate(cacheKey)) {
            Query<Map<String, dynamic>> serverQuery = _studentsCollection.where(
              'classId',
              isEqualTo: classId,
            );
            if (!includeArchived) {
              serverQuery = serverQuery.where('isArchived', isEqualTo: false);
            }
            unawaited(
              serverQuery
                  .limit(30)
                  .get(const GetOptions(source: Source.server))
                  .then((serverSnapshot) {
                    final result = mapStudentDocs(serverSnapshot.docs).students;
                    if (result.isNotEmpty) {
                      _localDatasource.saveStudents(result);
                      CacheTracker.markFetched(cacheKey);
                    }
                  })
                  .catchError((_) {}),
            );
          }

          return cached;
        }
      }

      try {
        Query<Map<String, dynamic>> serverQuery = _studentsCollection.where(
          'classId',
          isEqualTo: classId,
        );
        if (!includeArchived) {
          serverQuery = serverQuery.where('isArchived', isEqualTo: false);
        }

        serverQuery = serverQuery.limit(30);
        if (startAfter != null) {
          serverQuery = serverQuery.startAfterDocument(startAfter);
        }

        final serverSnapshot = await serverQuery.get(
          const GetOptions(source: Source.server),
        );
        final result = mapStudentDocs(serverSnapshot.docs).students;
        if (startAfter == null && result.isNotEmpty) {
          await _localDatasource.saveStudents(result);
        }
        return result;
      } on FirebaseException catch (e) {
        if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
          if (startAfter == null) {
            return await _localDatasource.getStudentsByClass(
              classId,
              includeArchived: includeArchived,
            );
          }
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
      final cached = await _localDatasource.getStudentsByGrade(
        grade,
        includeArchived: includeArchived,
      );
      if (cached.isNotEmpty) {
        final cacheKey = 'students_grade_${grade}_$includeArchived';
        if (CacheTracker.shouldRevalidate(cacheKey)) {
          var query = _studentsCollection
              .where('grade', isEqualTo: grade)
              .limit(100);
          if (!includeArchived) {
            query = query.where('isArchived', isEqualTo: false);
          }
          unawaited(
            query
                .get(const GetOptions(source: Source.server))
                .then((snapshot) {
                  final result = mapStudentDocs(snapshot.docs).students;
                  if (result.isNotEmpty) {
                    _localDatasource.saveStudents(result);
                    CacheTracker.markFetched(cacheKey);
                  }
                })
                .catchError((_) {}),
          );
        }
        return cached;
      }

      var query = _studentsCollection
          .where('grade', isEqualTo: grade)
          .limit(100);
      if (!includeArchived) {
        query = query.where('isArchived', isEqualTo: false);
      }
      final snapshot = await query.get();
      final result = mapStudentDocs(snapshot.docs).students;
      await _localDatasource.saveStudents(result);
      return result;
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  Future<List<StudentModel>> getStudentsByGroup(
    String groupName, {
    bool includeArchived = false,
  }) async {
    try {
      final cached = await _localDatasource.getStudentsByGroup(
        groupName,
        includeArchived: includeArchived,
      );
      if (cached.isNotEmpty) {
        final cacheKey = 'students_group_${groupName}_$includeArchived';
        if (CacheTracker.shouldRevalidate(cacheKey)) {
          var query = _studentsCollection
              .where('group', isEqualTo: groupName)
              .limit(100);
          if (!includeArchived) {
            query = query.where('isArchived', isEqualTo: false);
          }
          unawaited(
            query
                .get(const GetOptions(source: Source.server))
                .then((snapshot) {
                  final result = mapStudentDocs(snapshot.docs).students;
                  if (result.isNotEmpty) {
                    _localDatasource.saveStudents(result);
                    CacheTracker.markFetched(cacheKey);
                  }
                })
                .catchError((_) {}),
          );
        }
        return cached;
      }

      var query = _studentsCollection
          .where('group', isEqualTo: groupName)
          .limit(100);
      if (!includeArchived) {
        query = query.where('isArchived', isEqualTo: false);
      }
      final snapshot = await query.get();
      final result = mapStudentDocs(snapshot.docs).students;
      await _localDatasource.saveStudents(result);
      return result;
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
      final cached = await _localDatasource.getStudentsByGroup(
        groupName,
        includeArchived: includeArchived,
      );
      if (cached.isNotEmpty) {
        final cacheKey =
            'students_group_fallback_${groupName}_$includeArchived';
        if (CacheTracker.shouldRevalidate(cacheKey)) {
          unawaited(
            _studentsCollection
                .where('group', isEqualTo: groupName)
                .get(const GetOptions(source: Source.server))
                .then((serverSnapshot) {
                  final result = _applyArchivedFilter(
                    mapStudentDocs(serverSnapshot.docs).students,
                    includeArchived,
                  );
                  if (result.isNotEmpty) {
                    _localDatasource.saveStudents(result);
                    CacheTracker.markFetched(cacheKey);
                  }
                })
                .catchError((_) {}),
          );
        }

        return (students: cached, isFromCache: true);
      }
    } catch (e, stack) {
      developer.log('Cache read error', error: e, stackTrace: stack);
    }

    final serverSnapshot = await _studentsCollection
        .where('group', isEqualTo: groupName)
        .get();
    final result = _applyArchivedFilter(
      mapStudentDocs(serverSnapshot.docs).students,
      includeArchived,
    );
    await _localDatasource.saveStudents(result);
    return (students: result, isFromCache: false);
  }

  Future<StudentModel?> getStudentById(
    String docId, {
    bool includeArchived = false,
  }) async {
    try {
      final cached = await _localDatasource.getStudent(docId);
      if (cached != null) {
        if (!includeArchived && cached.isArchived) {
          return null;
        }
        return cached;
      }

      final doc = await _cachedGet(_studentsCollection.doc(docId));
      if (doc.exists && doc.data() != null) {
        final student = StudentModel.fromMap(doc.data()!, doc.id);
        await _localDatasource.saveStudent(student);
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

  ({List<StudentModel> students, DocumentSnapshot? lastDoc}) mapStudentDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final students = <StudentModel>[];
    for (final doc in docs) {
      try {
        students.add(StudentModel.fromMap(doc.data(), doc.id));
      } catch (error) {
        developer.log(
          'skipped malformed student document ${doc.reference.path}',
          error: error,
          name: 'StudentQueryService',
        );
      }
    }
    return (students: students, lastDoc: docs.isNotEmpty ? docs.last : null);
  }

  Future<List<StudentModel>> _getStudentsByDocumentIds(
    List<String> docIds,
  ) async {
    if (docIds.isEmpty) return [];

    final students = await _localDatasource.getStudentsByIds(
      docIds,
      includeArchived: true,
    );
    final foundIds = students.map((e) => e.docID).toSet();
    final missingIds = docIds.where((id) => !foundIds.contains(id)).toList();

    if (missingIds.isEmpty) {
      return students;
    }

    final chunks = missingIds.chunk(10);

    for (final chunk in chunks) {
      final snapshot = await _studentsCollection
          .where(FieldPath.documentId, whereIn: chunk)
          .get(const GetOptions(source: Source.server));
      final remoteStudents = mapStudentDocs(snapshot.docs).students;
      await _localDatasource.saveStudents(remoteStudents);
      students.addAll(remoteStudents);
    }

    return students;
  }

  List<StudentModel> _applyArchivedFilter(
    List<StudentModel> students,
    bool includeArchived,
  ) {
    if (includeArchived) return students;
    return students.where((s) => !s.isArchived).toList();
  }

  Future<List<StudentModel>> getStudentsByClasses(
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
    final chunks = classIds.chunk(10);
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

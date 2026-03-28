import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/domain/failures/student_failures.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

typedef StudentQueryDoc = QueryDocumentSnapshot<Map<String, dynamic>>;

class StudentQueryService {
  StudentQueryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _studentsCollection =>
      _firestore.collection(FirestoreCollections.students);

  List<StudentModel> mapStudentDocs(List<StudentQueryDoc> docs) {
    final students = <StudentModel>[];
    for (final doc in docs) {
      try {
        students.add(StudentModel.fromMap(doc.data(), doc.id));
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            'StudentQueryService: skipped malformed student doc '
            '${doc.id} (${e.runtimeType})',
          );
        }
      }
    }
    return students;
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

  Query<Map<String, dynamic>> _studentsByClassQuery(String classId) {
    return _studentsCollection.where('classId', isEqualTo: classId);
  }

  Query<Map<String, dynamic>> _studentsByGroupQuery(String groupName) {
    return _studentsCollection.where('group', isEqualTo: groupName);
  }

  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      final end = (i + chunkSize < list.length) ? i + chunkSize : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }

  Future<List<StudentModel>> _tryGetStudentsByClassFromCache(
    String classId,
  ) async {
    try {
      final cacheSnapshot = await _studentsByClassQuery(
        classId,
      ).get(const GetOptions(source: Source.cache));
      if (cacheSnapshot.docs.isNotEmpty) {
        return mapStudentDocs(cacheSnapshot.docs);
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
    return mapStudentDocs(snapshot.docs);
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
    final docs = results.expand((snap) => snap.docs).toList(growable: false);
    return mapStudentDocs(docs);
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

  Future<StudentModel?> getStudentByLinkedUserId(
    String linkedUserId, {
    bool includeArchived = false,
  }) async {
    try {
      final snapshot = await _studentsCollection
          .where('linkedUserId', isEqualTo: linkedUserId)
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
          mapStudentDocs(cacheSnapshot.docs),
          includeArchived,
        );
      }
    } catch (_) {}

    try {
      final serverSnapshot = await query.get(
        const GetOptions(source: Source.server),
      );
      return _applyArchivedFilter(
        mapStudentDocs(serverSnapshot.docs),
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
      final cacheStudents = _applyArchivedFilter(
        await _tryGetStudentsByClassFromCache(classId),
        includeArchived,
      );
      if (cacheStudents.isNotEmpty) {
        return cacheStudents;
      }

      final serverStudents = _applyArchivedFilter(
        await _getStudentsByClassFromServer(classId),
        includeArchived,
      );
      if (serverStudents.isNotEmpty) {
        return serverStudents;
      }

      final studentIds = await _getStudentIdsFromClassDocument(classId);
      return _applyArchivedFilter(
        await _getStudentsByDocumentIds(studentIds),
        includeArchived,
      );
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  Future<List<StudentModel>> getStudentsByGrade(int grade) async {
    try {
      final snapshot = await _studentsCollection
          .where('grade', isEqualTo: grade)
          .get();
      return mapStudentDocs(snapshot.docs);
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  Future<List<StudentModel>> getStudentsByGroup(
    String groupName, {
    bool includeArchived = false,
  }) async {
    try {
      final snapshot = await _studentsByGroupQuery(groupName).get();
      return _applyArchivedFilter(
        mapStudentDocs(snapshot.docs),
        includeArchived,
      );
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  Future<List<StudentModel>> searchStudents(
    String query, {
    int limit = 20,
    bool includeArchived = false,
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return getAllStudents(limit: limit, includeArchived: includeArchived);
    }

    try {
      Query<Map<String, dynamic>> firestoreQuery = _studentsCollection
          .where('nameLower', isGreaterThanOrEqualTo: normalizedQuery)
          .where('nameLower', isLessThanOrEqualTo: '$normalizedQuery\uf8ff')
          .orderBy('nameLower')
          .limit(limit);

      if (!includeArchived) {
        firestoreQuery = firestoreQuery.where('isArchived', isEqualTo: false);
      }

      final snapshot = await firestoreQuery.get();
      return _applyArchivedFilter(mapStudentDocs(snapshot.docs), includeArchived);
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  Future<StudentQueryPage> getStudentsPage({
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    String? classId,
    List<String>? classIds,
    String? groupName,
    bool includeArchived = false,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _studentsCollection.orderBy('name');

      final normalizedClassId = classId?.trim();
      final normalizedGroupName = groupName?.trim();
      final normalizedClassIds = (classIds ?? const <String>[])
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(growable: false);

      if (normalizedClassId != null && normalizedClassId.isNotEmpty) {
        query = query.where('classId', isEqualTo: normalizedClassId);
      } else if (normalizedClassIds.isNotEmpty) {
        query = query.where('classId', whereIn: normalizedClassIds);
      } else if (normalizedGroupName != null && normalizedGroupName.isNotEmpty) {
        query = query.where('group', isEqualTo: normalizedGroupName);
      }

      query = query.limit(limit + 1);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final hasMore = snapshot.docs.length > limit;
      final pageDocs = hasMore
          ? snapshot.docs.take(limit).toList(growable: false)
          : snapshot.docs;
      final students = _applyArchivedFilter(
        mapStudentDocs(pageDocs),
        includeArchived,
      );

      return StudentQueryPage(
        students: students,
        lastDocument: pageDocs.isEmpty ? lastDocument : pageDocs.last,
        hasReachedMax: !hasMore,
      );
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
            mapStudentDocs(cacheSnapshot.docs),
            includeArchived,
          ),
          isFromCache: true,
        );
      }
    } catch (_) {}

    try {
      final serverSnapshot = await _studentsByGroupQuery(
        groupName,
      ).get(const GetOptions(source: Source.server));
      return (
        students: _applyArchivedFilter(
          mapStudentDocs(serverSnapshot.docs),
          includeArchived,
        ),
        isFromCache: false,
      );
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  Future<List<String>> getStudentIdsByClasses(List<String> classIds) async {
    if (classIds.isEmpty) return [];

    final studentIds = <String>[];
    final chunks = _chunkList(classIds, 10);
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

  Stream<List<StudentModel>> watchAllStudents({bool includeArchived = false}) {
    return _studentsCollection
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => _applyArchivedFilter(
            mapStudentDocs(snapshot.docs),
            includeArchived,
          ),
        );
  }

  Stream<List<StudentModel>> watchStudentsByClass(
    String classId, {
    bool includeArchived = false,
  }) {
    return _studentsCollection
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map(
          (snapshot) => _applyArchivedFilter(
            mapStudentDocs(snapshot.docs),
            includeArchived,
          ),
        );
  }

  Stream<List<StudentModel>> watchStudentsByClasses(
    List<String> classIds, {
    bool includeArchived = false,
  }) {
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
                (snapshot) => _applyArchivedFilter(
                  mapStudentDocs(snapshot.docs),
                  includeArchived,
                ),
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
      return byDocId.values.toList(growable: false);
    });
  }

  Stream<List<StudentModel>> watchStudentsByGroup(
    String groupName, {
    bool includeArchived = false,
  }) {
    return _studentsCollection
        .where('group', isEqualTo: groupName)
        .snapshots()
        .map(
          (snapshot) => _applyArchivedFilter(
            mapStudentDocs(snapshot.docs),
            includeArchived,
          ),
        );
  }
}

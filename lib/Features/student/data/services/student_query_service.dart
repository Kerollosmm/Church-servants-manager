import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/domain/failures/student_failures.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

class StudentQueryService {
  StudentQueryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _studentsCollection =>
      _firestore.collection(FirestoreCollections.students);

  List<StudentModel> mapStudentDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
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
        return mapStudentDocs(cacheSnapshot.docs);
      }
    } catch (_) {}

    try {
      final serverSnapshot = await query.get(
        const GetOptions(source: Source.server),
      );
      return mapStudentDocs(serverSnapshot.docs);
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  Future<List<StudentModel>> getStudentsByClass(String classId) async {
    try {
      final cacheStudents = await _tryGetStudentsByClassFromCache(classId);
      if (cacheStudents.isNotEmpty) {
        return cacheStudents;
      }

      final serverStudents = await _getStudentsByClassFromServer(classId);
      if (serverStudents.isNotEmpty) {
        return serverStudents;
      }

      final studentIds = await _getStudentIdsFromClassDocument(classId);
      return _getStudentsByDocumentIds(studentIds);
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

  Future<List<StudentModel>> getStudentsByGroup(String groupName) async {
    try {
      final snapshot = await _studentsByGroupQuery(groupName).get();
      return mapStudentDocs(snapshot.docs);
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
          students: mapStudentDocs(cacheSnapshot.docs),
          isFromCache: true,
        );
      }
    } catch (_) {}

    try {
      final serverSnapshot = await _studentsByGroupQuery(
        groupName,
      ).get(const GetOptions(source: Source.server));
      return (
        students: mapStudentDocs(serverSnapshot.docs),
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

  Stream<List<StudentModel>> watchAllStudents() {
    return _studentsCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) => mapStudentDocs(snapshot.docs));
  }

  Stream<List<StudentModel>> watchStudentsByClass(String classId) {
    return _studentsCollection
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) => mapStudentDocs(snapshot.docs));
  }

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
              .map((snapshot) => mapStudentDocs(snapshot.docs)),
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

  Stream<List<StudentModel>> watchStudentsByGroup(String groupName) {
    return _studentsCollection
        .where('group', isEqualTo: groupName)
        .snapshots()
        .map((snapshot) => mapStudentDocs(snapshot.docs));
  }
}

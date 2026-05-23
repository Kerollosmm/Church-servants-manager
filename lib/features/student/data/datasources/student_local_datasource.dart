import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:hive/hive.dart';

class StudentLocalDatasource {
  static const String boxName = 'students_box';
  static const String syncQueueBoxName = 'students_sync_queue_box';

  Box<StudentModel>? _studentsBox;
  Box<StudentModel>? _syncQueueBox;
  Future<void>? _initFuture;

  Future<void> init() {
    _initFuture ??= _doInit();
    return _initFuture!;
  }

  Future<void> _doInit() async {
    _studentsBox = await Hive.openBox<StudentModel>(boxName);
    _syncQueueBox = await Hive.openBox<StudentModel>(syncQueueBoxName);
  }

  Future<void> saveStudent(StudentModel student) async {
    await init();
    await _studentsBox!.put(student.docID, student);
  }

  Future<StudentModel?> getStudent(String docId) async {
    await init();
    try {
      return _studentsBox!.get(docId);
    } catch (_) {
      // Corrupted entry – remove and return null.
      await _studentsBox!.delete(docId);
      return null;
    }
  }

  Future<List<StudentModel>> getAllStudents({
    bool includeArchived = false,
  }) async {
    await init();
    final students = <StudentModel>[];
    final corruptedKeys = <dynamic>[];
    for (final key in _studentsBox!.keys) {
      try {
        final s = _studentsBox!.get(key);
        if (s != null) {
          if (includeArchived || !s.isArchived) {
            students.add(s);
          }
        }
      } catch (_) {
        // Corrupted entry (e.g. null in a non-nullable bool field) – mark for removal.
        corruptedKeys.add(key);
      }
    }
    if (corruptedKeys.isNotEmpty) {
      await _studentsBox!.deleteAll(corruptedKeys);
    }
    return students;
  }

  Future<List<StudentModel>> getStudentsByClass(
    String classId, {
    bool includeArchived = false,
  }) async {
    await init();
    final students = <StudentModel>[];
    final corruptedKeys = <dynamic>[];
    for (final key in _studentsBox!.keys) {
      try {
        final s = _studentsBox!.get(key);
        if (s != null && s.classId == classId) {
          if (includeArchived || !s.isArchived) {
            students.add(s);
          }
        }
      } catch (_) {
        corruptedKeys.add(key);
      }
    }
    if (corruptedKeys.isNotEmpty) {
      await _studentsBox!.deleteAll(corruptedKeys);
    }
    return students;
  }

  Future<List<StudentModel>> getStudentsByGrade(
    int grade, {
    bool includeArchived = false,
  }) async {
    await init();
    final students = <StudentModel>[];
    final corruptedKeys = <dynamic>[];
    for (final key in _studentsBox!.keys) {
      try {
        final s = _studentsBox!.get(key);
        if (s != null && s.grade == grade) {
          if (includeArchived || !s.isArchived) {
            students.add(s);
          }
        }
      } catch (_) {
        corruptedKeys.add(key);
      }
    }
    if (corruptedKeys.isNotEmpty) {
      await _studentsBox!.deleteAll(corruptedKeys);
    }
    return students;
  }

  Future<List<StudentModel>> getStudentsByGroup(
    String groupName, {
    bool includeArchived = false,
  }) async {
    await init();
    final students = <StudentModel>[];
    final corruptedKeys = <dynamic>[];
    for (final key in _studentsBox!.keys) {
      try {
        final s = _studentsBox!.get(key);
        if (s != null && s.group.name == groupName) {
          if (includeArchived || !s.isArchived) {
            students.add(s);
          }
        }
      } catch (_) {
        corruptedKeys.add(key);
      }
    }
    if (corruptedKeys.isNotEmpty) {
      await _studentsBox!.deleteAll(corruptedKeys);
    }
    return students;
  }

  Future<List<StudentModel>> getStudentsByIds(
    List<String> docIds, {
    bool includeArchived = false,
  }) async {
    await init();
    final students = <StudentModel>[];
    final corruptedKeys = <dynamic>[];
    for (final id in docIds) {
      try {
        final s = _studentsBox!.get(id);
        if (s != null) {
          if (includeArchived || !s.isArchived) {
            students.add(s);
          }
        }
      } catch (_) {
        corruptedKeys.add(id);
      }
    }
    if (corruptedKeys.isNotEmpty) {
      await _studentsBox!.deleteAll(corruptedKeys);
    }
    return students;
  }

  Future<void> saveStudents(List<StudentModel> students) async {
    await init();
    final map = {for (final s in students) s.docID: s};
    await _studentsBox!.putAll(map);
  }

  Future<void> queueForSync(StudentModel student) async {
    await init();
    await _syncQueueBox!.put(student.docID, student);
  }

  Future<void> removeFromSyncQueue(String docId) async {
    await init();
    await _syncQueueBox!.delete(docId);
  }
}

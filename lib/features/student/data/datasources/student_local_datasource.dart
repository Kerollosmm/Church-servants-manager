import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:hive/hive.dart';

class StudentLocalDatasource {
  static const String boxName = 'students_box';
  static const String syncQueueBoxName = 'students_sync_queue_box';

  Box<StudentModel>? _studentsBox;
  Box<StudentModel>? _syncQueueBox;

  Future<void> init() async {
    _studentsBox ??= await Hive.openBox<StudentModel>(boxName);
    _syncQueueBox ??= await Hive.openBox<StudentModel>(syncQueueBoxName);
  }

  Future<void> saveStudent(StudentModel student) async {
    await init();
    await _studentsBox!.put(student.docID, student);
  }

  Future<StudentModel?> getStudent(String docId) async {
    await init();
    return _studentsBox!.get(docId);
  }

  Future<List<StudentModel>> getAllStudents({
    bool includeArchived = false,
  }) async {
    await init();
    final students = _studentsBox!.values.toList();
    if (!includeArchived) {
      return students.where((s) => !s.isArchived).toList();
    }
    return students;
  }

  Future<List<StudentModel>> getStudentsByClass(
    String classId, {
    bool includeArchived = false,
  }) async {
    await init();
    final students = _studentsBox!.values
        .where((s) => s.classId == classId)
        .toList();
    if (!includeArchived) {
      return students.where((s) => !s.isArchived).toList();
    }
    return students;
  }

  Future<List<StudentModel>> getStudentsByGrade(
    int grade, {
    bool includeArchived = false,
  }) async {
    await init();
    final students = _studentsBox!.values
        .where((s) => s.grade == grade)
        .toList();
    if (!includeArchived) {
      return students.where((s) => !s.isArchived).toList();
    }
    return students;
  }

  Future<List<StudentModel>> getStudentsByGroup(
    String groupName, {
    bool includeArchived = false,
  }) async {
    await init();
    final students = _studentsBox!.values
        .where((s) => s.group.name == groupName)
        .toList();
    if (!includeArchived) {
      return students.where((s) => !s.isArchived).toList();
    }
    return students;
  }

  Future<List<StudentModel>> getStudentsByIds(
    List<String> docIds, {
    bool includeArchived = false,
  }) async {
    await init();
    final students = <StudentModel>[];
    for (final id in docIds) {
      final s = _studentsBox!.get(id);
      if (s != null) {
        if (includeArchived || !s.isArchived) {
          students.add(s);
        }
      }
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

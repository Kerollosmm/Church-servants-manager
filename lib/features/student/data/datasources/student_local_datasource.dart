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

  Future<void> queueForSync(StudentModel student) async {
    await init();
    await _syncQueueBox!.put(student.docID, student);
  }

  Future<void> removeFromSyncQueue(String docId) async {
    await init();
    await _syncQueueBox!.delete(docId);
  }
}

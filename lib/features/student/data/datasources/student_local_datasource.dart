import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:hive/hive.dart';

class StudentLocalDatasource {
  static const String boxName = 'students_box';
  static const String syncQueueBoxName = 'students_sync_queue_box';

  Box<dynamic>? _studentsBox;
  Box<dynamic>? _syncQueueBox;

  Future<void> init() async {
    _studentsBox ??= await Hive.openBox(boxName);
    _syncQueueBox ??= await Hive.openBox(syncQueueBoxName);
  }

  Future<void> saveStudent(StudentModel student) async {
    await init();
    // In a real Hive setup with TypeAdapters, we could store the object directly.
    // For now, assuming basic Hive storage, we store it as a Map.
    await _studentsBox!.put(student.docID, student.toMap());
  }

  Future<StudentModel?> getStudent(String docId) async {
    await init();
    final data = _studentsBox!.get(docId);
    if (data != null) {
      // Cast the Hive dynamic map to Map<String, dynamic>
      final map = Map<String, dynamic>.from(data as Map);
      return StudentModel.fromMap(map, docId);
    }
    return null;
  }

  Future<void> queueForSync(StudentModel student) async {
    await init();
    await _syncQueueBox!.put(student.docID, student.toMap());
  }

  Future<void> removeFromSyncQueue(String docId) async {
    await init();
    await _syncQueueBox!.delete(docId);
  }
}

import 'package:church_managment_system/core/models/auth_user.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';

class StudentDetailArgs {
  final AuthUser actor;
  final StudentModel student;

  const StudentDetailArgs({required this.actor, required this.student});
}

class StudentEditArgs {
  final AuthUser actor;
  final StudentModel? student;

  const StudentEditArgs({required this.actor, this.student});

  bool get isEditing => student != null;
}


import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/servant/data/models/servant_models.dart';

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

class ServantDetailArgs {
  final AuthUser actor;
  final ServantModel servant;

  const ServantDetailArgs({required this.actor, required this.servant});
}

class ServantEditArgs {
  final AuthUser actor;
  final ServantModel? servant;

  const ServantEditArgs({required this.actor, this.servant});

  bool get isEditing => servant != null;
}

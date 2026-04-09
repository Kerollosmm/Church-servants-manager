import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';

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

class TeamMembersArgs {
  final AuthUser actor;
  final TeamModel team;

  const TeamMembersArgs({required this.actor, required this.team});
}

class AttendanceTakingArgs {
  final AuthUser actor;
  final String teamId;
  final String sessionId;

  const AttendanceTakingArgs({
    required this.actor,
    required this.teamId,
    required this.sessionId,
  });
}

class StudentAttendanceArgs {
  final AuthUser actor;
  final String studentId;
  final String studentName;
  final String? filterTeamId;

  const StudentAttendanceArgs({
    required this.actor,
    required this.studentId,
    required this.studentName,
    this.filterTeamId,
  });
}

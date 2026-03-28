import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';

class SearchStudentsUseCase {
  const SearchStudentsUseCase(this._repository);

  final IStudentRepository _repository;

  Future<List<StudentModel>> call({
    required AuthUser actor,
    required String query,
    int limit = 20,
    String? teamId,
    bool includeArchived = false,
  }) async {
    final results = await _repository.searchStudents(
      query,
      limit: limit,
      includeArchived: includeArchived,
    );

    return results
        .where(
          (student) => _isVisibleToActor(actor, student: student, teamId: teamId),
        )
        .toList(growable: false);
  }

  bool _isVisibleToActor(
    AuthUser actor, {
    required StudentModel student,
    String? teamId,
  }) {
    switch (actor.role) {
      case UserRole.admin:
        return teamId == null || teamId.isEmpty || student.classId == teamId;
      case UserRole.servant:
        final assignedTeamIds = actor.effectiveAssignedTeamIds
            .where((id) => id.trim().isNotEmpty)
            .toSet();

        if (assignedTeamIds.isNotEmpty) {
          if (teamId != null && teamId.isNotEmpty) {
            return assignedTeamIds.contains(teamId) && student.classId == teamId;
          }
          return student.classId != null &&
              assignedTeamIds.contains(student.classId);
        }

        final groupId = actor.groupId?.trim() ?? '';
        return groupId.isNotEmpty && student.group.name == groupId;
      case UserRole.student:
        return false;
    }
  }
}

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';

/// Returns a Future [List] of students filtered by the
/// actor's role and optional team filter.
class GetStudentsListUseCase {
  final IStudentRepository _repository;

  const GetStudentsListUseCase(this._repository);

  /// Returns a Future or `null` if the actor has no access.
  Future<List<StudentModel>?> call({
    required AuthUser actor,
    String? teamId,
    bool includeArchived = false,
  }) async {
    if (actor.isArchived) return null;

    switch (actor.role) {
      case UserRole.admin:
        if (teamId != null && teamId.isNotEmpty) {
          return _repository.getStudentsByClass(
            teamId,
            includeArchived: includeArchived,
          );
        } else {
          return _repository.getAllStudents(
            limit: 50,
            includeArchived: includeArchived,
          );
        }

      case UserRole.servant:
        final assignedTeamIds = actor.effectiveAssignedTeamIds;
        if (assignedTeamIds.isNotEmpty) {
          if (teamId != null && teamId.isNotEmpty) {
            if (!assignedTeamIds.contains(teamId)) return null;
            return _repository.getStudentsByClass(
              teamId,
              includeArchived: includeArchived,
            );
          } else if (assignedTeamIds.length == 1) {
            return _repository.getStudentsByClass(
              assignedTeamIds.first,
              includeArchived: includeArchived,
            );
          } else {
            return _repository.getStudentsByClasses(
              assignedTeamIds,
              includeArchived: includeArchived,
            );
          }
        } else {
          final groupId = actor.groupId;
          if (groupId == null || groupId.isEmpty) return null;
          return _repository.getStudentsByGroup(
            groupId,
            includeArchived: includeArchived,
          );
        }

      case UserRole.student:
        return null;
    }
  }
}

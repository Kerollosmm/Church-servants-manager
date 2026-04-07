import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:rxdart/rxdart.dart';

/// Returns a real-time [Stream] of students filtered by the
/// actor's role and optional team filter.
class GetStudentsStreamUseCase {
  final StudentDataRepository _repository;

  const GetStudentsStreamUseCase(this._repository);

  /// Returns a stream or `null` if the actor has no access.
  /// Uses [shareReplay] to ensure multiple listeners share the same active Firestore subscription.
  Stream<List<StudentModel>>? call({
    required AuthUser actor,
    String? teamId,
    bool includeArchived = false,
  }) {
    if (actor.isArchived) return null;
    Stream<List<StudentModel>>? stream;

    switch (actor.role) {
      case UserRole.admin:
        if (teamId != null && teamId.isNotEmpty) {
          stream = _repository.watchStudentsByClass(
            teamId,
            includeArchived: includeArchived,
          );
        } else {
          stream = _repository.watchAllStudents(
            includeArchived: includeArchived,
          );
        }
        break;

      case UserRole.servant:
        final assignedTeamIds = actor.effectiveAssignedTeamIds;
        if (assignedTeamIds.isNotEmpty) {
          if (teamId != null && teamId.isNotEmpty) {
            if (!assignedTeamIds.contains(teamId)) return null;
            stream = _repository.watchStudentsByClass(
              teamId,
              includeArchived: includeArchived,
            );
          } else if (assignedTeamIds.length == 1) {
            stream = _repository.watchStudentsByClass(
              assignedTeamIds.first,
              includeArchived: includeArchived,
            );
          } else {
            stream = _repository.watchStudentsByClasses(
              assignedTeamIds,
              includeArchived: includeArchived,
            );
          }
        } else {
          final groupId = actor.groupId;
          if (groupId == null || groupId.isEmpty) return null;
          stream = _repository.watchStudentsByGroup(
            groupId,
            includeArchived: includeArchived,
          );
        }
        break;

      case UserRole.student:
        return null;
    }

    return stream.shareReplay(maxSize: 1);
  }
}

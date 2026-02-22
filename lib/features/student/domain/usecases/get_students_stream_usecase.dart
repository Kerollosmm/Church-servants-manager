import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/domain/repos/i_student_repository.dart';
import 'package:rxdart/rxdart.dart';

/// Returns a real-time [Stream] of students filtered by the
/// actor's role and optional team filter.
class GetStudentsStreamUseCase {
  final IStudentRepository _repository;

  const GetStudentsStreamUseCase(this._repository);

  /// Returns a stream or `null` if the actor has no access.
  /// Uses [shareReplay] to ensure multiple listeners share the same active Firestore subscription.
  Stream<List<StudentModel>>? call({required AuthUser actor, String? teamId}) {
    Stream<List<StudentModel>>? stream;

    switch (actor.role) {
      case UserRole.admin:
        if (teamId != null && teamId.isNotEmpty) {
          stream = _repository.watchStudentsByClass(teamId);
        } else {
          stream = _repository.watchAllStudents();
        }
        break;

      case UserRole.servant:
        final assignedTeamIds = actor.effectiveAssignedTeamIds;
        if (assignedTeamIds.isNotEmpty) {
          if (teamId != null && teamId.isNotEmpty) {
            if (!assignedTeamIds.contains(teamId)) return null;
            stream = _repository.watchStudentsByClass(teamId);
          } else if (assignedTeamIds.length == 1) {
            stream = _repository.watchStudentsByClass(assignedTeamIds.first);
          } else {
            stream = _repository.watchStudentsByClasses(assignedTeamIds);
          }
        } else {
          final groupId = actor.groupId;
          if (groupId == null || groupId.isEmpty) return null;
          stream = _repository.watchStudentsByGroup(groupId);
        }
        break;

      case UserRole.student:
        return null;
    }

    return stream.shareReplay(maxSize: 1);
  }
}

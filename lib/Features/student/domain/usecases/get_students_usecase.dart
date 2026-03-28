import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_stream_usecase.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// FIX [P1]: extracted student loading/lookups behind a use case.
class GetStudentsUseCase {
  const GetStudentsUseCase(this._repository, this._getStudentsStreamUseCase);

  final IStudentRepository _repository;
  final GetStudentsStreamUseCase _getStudentsStreamUseCase;

  Stream<List<StudentModel>>? watch({
    required AuthUser actor,
    String? teamId,
    bool includeArchived = false,
  }) {
    return _getStudentsStreamUseCase(
      actor: actor,
      teamId: teamId,
      includeArchived: includeArchived,
    );
  }

  Future<StudentModel?> findById(String docId, {bool includeArchived = false}) {
    return _repository.getStudentById(docId, includeArchived: includeArchived);
  }

  Future<StudentsPage> fetchPage({
    required AuthUser actor,
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    String? teamId,
    bool includeArchived = false,
  }) async {
    switch (actor.role) {
      case UserRole.admin:
        final page = await _repository.getStudentsPage(
          limit: limit,
          lastDocument: lastDocument,
          classId: teamId,
          includeArchived: includeArchived,
        );
        return StudentsPage.fromRepositoryPage(page);

      case UserRole.servant:
        final assignedTeamIds = actor.effectiveAssignedTeamIds
            .where((id) => id.trim().isNotEmpty)
            .toSet()
            .toList(growable: false);

        if (assignedTeamIds.isNotEmpty) {
          if (teamId != null && teamId.isNotEmpty) {
            if (!assignedTeamIds.contains(teamId)) {
              return const StudentsPage.empty();
            }
            final page = await _repository.getStudentsPage(
              limit: limit,
              lastDocument: lastDocument,
              classId: teamId,
              includeArchived: includeArchived,
            );
            return StudentsPage.fromRepositoryPage(page);
          }

          final page = await _repository.getStudentsPage(
            limit: limit,
            lastDocument: lastDocument,
            classIds: assignedTeamIds,
            includeArchived: includeArchived,
          );
          return StudentsPage.fromRepositoryPage(page);
        }

        final groupId = actor.groupId?.trim() ?? '';
        if (groupId.isEmpty) {
          return const StudentsPage.empty();
        }
        final page = await _repository.getStudentsPage(
          limit: limit,
          lastDocument: lastDocument,
          groupName: groupId,
          includeArchived: includeArchived,
        );
        return StudentsPage.fromRepositoryPage(page);

      case UserRole.student:
        return const StudentsPage.empty();
    }
  }
}

/// Result of a single page fetch for student pagination.
class StudentsPage {
  const StudentsPage({
    required this.students,
    required this.lastDocument,
    required this.hasReachedMax,
  });

  final List<StudentModel> students;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasReachedMax;

  const StudentsPage.empty()
    : students = const <StudentModel>[],
      lastDocument = null,
      hasReachedMax = true;

  factory StudentsPage.fromRepositoryPage(StudentQueryPage page) {
    return StudentsPage(
      students: page.students,
      lastDocument: page.lastDocument,
      hasReachedMax: page.hasReachedMax,
    );
  }
}

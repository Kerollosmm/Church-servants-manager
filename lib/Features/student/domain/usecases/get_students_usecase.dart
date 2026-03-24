import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_stream_usecase.dart';

// FIX [P1]: extracted student loading/lookups behind a use case.
class GetStudentsUseCase {
  const GetStudentsUseCase(this._repository, this._getStudentsStreamUseCase);

  final StudentDataRepository _repository;
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

  List<StudentModel> _sortStudents(List<StudentModel> students) {
    final sorted = List<StudentModel>.from(students);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  StudentsPage _pageFromStudents(
    List<StudentModel> students, {
    required int offset,
    required int limit,
  }) {
    final sorted = _sortStudents(students);
    final page = sorted.skip(offset).take(limit).toList(growable: false);
    final hasMore = sorted.length > offset + limit;
    return StudentsPage(students: page, hasMore: hasMore);
  }

  Future<List<StudentModel>> _loadScopedStudents({
    required AuthUser actor,
    String? teamId,
    required bool includeArchived,
  }) async {
    switch (actor.role) {
      case UserRole.admin:
        if (teamId != null && teamId.isNotEmpty) {
          return _repository.getStudentsByClass(
            teamId,
            includeArchived: includeArchived,
          );
        }
        return _repository.getAllStudents(includeArchived: includeArchived);

      case UserRole.servant:
        final assignedTeamIds = actor.effectiveAssignedTeamIds
            .where((id) => id.trim().isNotEmpty)
            .toSet()
            .toList(growable: false);

        if (assignedTeamIds.isNotEmpty) {
          if (teamId != null && teamId.isNotEmpty) {
            if (!assignedTeamIds.contains(teamId)) {
              return const <StudentModel>[];
            }
            return _repository.getStudentsByClass(
              teamId,
              includeArchived: includeArchived,
            );
          }

          if (assignedTeamIds.length == 1) {
            return _repository.getStudentsByClass(
              assignedTeamIds.first,
              includeArchived: includeArchived,
            );
          }

          // FIX [009-P1]: keep load-more scoped to the servant's assigned teams.
          final results = await Future.wait(
            assignedTeamIds.map(
              (assignedTeamId) => _repository.getStudentsByClass(
                assignedTeamId,
                includeArchived: includeArchived,
              ),
            ),
          );
          final merged = <String, StudentModel>{};
          for (final students in results) {
            for (final student in students) {
              merged[student.docID] = student;
            }
          }
          return merged.values.toList(growable: false);
        }

        final groupId = actor.groupId?.trim() ?? '';
        if (groupId.isEmpty) {
          return const <StudentModel>[];
        }
        return _repository.getStudentsByGroup(
          groupId,
          includeArchived: includeArchived,
        );

      case UserRole.student:
        return const <StudentModel>[];
    }
  }

  // FIX [009-P2]: keep page fetches aligned with the same actor/team scope as the live stream.
  Future<StudentsPage> fetchPage({
    required AuthUser actor,
    int limit = 20,
    int offset = 0,
    String? teamId,
    bool includeArchived = false,
  }) async {
    if (actor.role == UserRole.admin && (teamId == null || teamId.isEmpty)) {
      final all = await _repository.getAllStudents(
        limit: offset + limit + 1,
        includeArchived: includeArchived,
      );
      final sorted = _sortStudents(all);
      final page = sorted.skip(offset).take(limit).toList(growable: false);
      final hasMore = sorted.length > offset + limit;
      return StudentsPage(students: page, hasMore: hasMore);
    }

    final scopedStudents = await _loadScopedStudents(
      actor: actor,
      teamId: teamId,
      includeArchived: includeArchived,
    );
    return _pageFromStudents(scopedStudents, offset: offset, limit: limit);
  }
}

/// Result of a single page fetch for student pagination.
// FIX [008]: Simple value holder for paginated student results. (T008)
class StudentsPage {
  const StudentsPage({required this.students, required this.hasMore});

  final List<StudentModel> students;
  final bool hasMore;
}

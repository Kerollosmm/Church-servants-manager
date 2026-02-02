part of 'student_data_bloc.dart';

/// Sealed events for StudentDataBloc (past tense naming convention).
sealed class StudentDataEvent {
  const StudentDataEvent();
}

/// Load students with optional group filter.
/// UI passes filterGroupId from RoleCubit - decoupled design.
final class StudentsLoadRequested extends StudentDataEvent {
  final String? filterGroupId;
  final int limit;

  const StudentsLoadRequested({this.filterGroupId, this.limit = 50});
}

/// Create a new student.
final class StudentCreated extends StudentDataEvent {
  final StudentModel student;

  const StudentCreated(this.student);
}

/// Update an existing student.
final class StudentUpdated extends StudentDataEvent {
  final StudentModel student;

  const StudentUpdated(this.student);
}

/// Delete a student by document ID.
final class StudentDeleted extends StudentDataEvent {
  final String docId;

  const StudentDeleted(this.docId);
}

/// Refresh students (re-fetch with current filter).
final class StudentsRefreshRequested extends StudentDataEvent {
  const StudentsRefreshRequested();
}

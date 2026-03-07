part of 'student_data_bloc.dart';

/// Sealed events for StudentDataBloc (past tense naming convention).
sealed class StudentDataEvent {
  const StudentDataEvent();
}

/// Load students with optional team filter.
final class StudentsLoadRequested extends StudentDataEvent {
  final AuthUser actor;
  final int limit;
  final String? teamId;

  const StudentsLoadRequested({
    required this.actor,
    this.limit = 50,
    this.teamId,
  });
}

/// Search students by name (BLoC-managed, no direct repository calls in UI).
final class StudentsSearchRequested extends StudentDataEvent {
  final AuthUser actor;
  final String query;
  final String? teamId;

  const StudentsSearchRequested({
    required this.actor,
    required this.query,
    this.teamId,
  });
}

/// Create a new student.
final class StudentCreated extends StudentDataEvent {
  final AuthUser actor;
  final StudentModel student;
  final String? email;
  final String? password;

  const StudentCreated({
    required this.actor,
    required this.student,
    this.email,
    this.password,
  });
}

/// Update an existing student.
final class StudentUpdated extends StudentDataEvent {
  final AuthUser actor;
  final StudentModel student;

  const StudentUpdated({required this.actor, required this.student});
}

/// Delete a student by document ID.
final class StudentDeleted extends StudentDataEvent {
  final AuthUser actor;
  final String docId;

  const StudentDeleted({required this.actor, required this.docId});
}

/// Refresh students (re-fetch with current filter).
final class StudentsRefreshRequested extends StudentDataEvent {
  final AuthUser actor;

  const StudentsRefreshRequested({required this.actor});
}

/// Stop active Firestore listening and clear in-memory list cache.
final class StudentsListeningStopped extends StudentDataEvent {
  const StudentsListeningStopped();
}

/// Internal event: fired when the Firestore stream emits new data.
final class _StudentsStreamUpdated extends StudentDataEvent {
  final List<StudentModel> students;

  const _StudentsStreamUpdated(this.students);
}

/// Internal event: fired when the Firestore stream encounters an error.
final class _StreamError extends StudentDataEvent {
  final String message;

  const _StreamError(this.message);
}

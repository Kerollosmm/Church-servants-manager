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
  final bool includeArchived;

  const StudentsLoadRequested({
    required this.actor,
    this.limit = 50,
    this.teamId,
    this.includeArchived = false,
  });
}

/// Search students by name (BLoC-managed, no direct repository calls in UI).
final class StudentsSearchRequested extends StudentDataEvent {
  final AuthUser actor;
  final String query;
  final String? teamId;
  final bool includeArchived;

  const StudentsSearchRequested({
    required this.actor,
    required this.query,
    this.teamId,
    this.includeArchived = false,
  });
}

/// Create a new student.
final class StudentCreated extends StudentDataEvent {
  final AuthUser actor;
  final Student student;
  final String? email;

  const StudentCreated({
    required this.actor,
    required this.student,
    this.email,
  });
}

/// Update an existing student.
final class StudentUpdated extends StudentDataEvent {
  final AuthUser actor;
  final Student student;

  const StudentUpdated({required this.actor, required this.student});
}

/// Archive a student by document ID.
final class StudentDeleted extends StudentDataEvent {
  final AuthUser actor;
  final String docId;

  const StudentDeleted({required this.actor, required this.docId});
}

final class StudentRestored extends StudentDataEvent {
  final AuthUser actor;
  final String docId;

  const StudentRestored({required this.actor, required this.docId});
}

/// Refresh students (re-fetch with current filter).
final class StudentsRefreshRequested extends StudentDataEvent {
  final AuthUser actor;
  final bool includeArchived;

  const StudentsRefreshRequested({
    required this.actor,
    this.includeArchived = false,
  });
}

/// Stop active Firestore listening and clear in-memory list cache.
final class StudentsListeningStopped extends StudentDataEvent {
  const StudentsListeningStopped();
}

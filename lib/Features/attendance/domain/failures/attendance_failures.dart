import 'package:church_management_system/core/utils/exception_matchers.dart';
import 'package:equatable/equatable.dart';

abstract class AttendanceFailure extends Equatable implements Exception {
  const AttendanceFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

class AttendanceSessionNotFoundFailure extends AttendanceFailure {
  const AttendanceSessionNotFoundFailure([
    super.message = 'تعذر العثور على جلسة الحضور.',
  ]);
}

class AttendanceSessionClosedFailure extends AttendanceFailure {
  const AttendanceSessionClosedFailure([
    super.message = 'انتهى وقت تسجيل الحضور لهذه الجلسة.',
  ]);
}

class AttendanceSessionConflictFailure extends AttendanceFailure {
  const AttendanceSessionConflictFailure([
    super.message = 'توجد جلسة حضور متعارضة أو مفتوحة بالفعل لهذه المجموعة.',
  ]);
}

class AttendancePermissionDeniedFailure extends AttendanceFailure {
  const AttendancePermissionDeniedFailure([
    super.message = 'ليس لديك صلاحية لتسجيل الحضور لهذه المجموعة.',
  ]);
}

class AttendanceStudentNotInSessionFailure extends AttendanceFailure {
  const AttendanceStudentNotInSessionFailure([
    super.message = 'هذا المخدوم غير مسجل ضمن هذه الجلسة.',
  ]);
}

class AttendanceValidationFailure extends AttendanceFailure {
  const AttendanceValidationFailure(super.message);
}

class AttendanceServerFailure extends AttendanceFailure {
  const AttendanceServerFailure([
    super.message = 'تعذر الاتصال بالخادم. حاول مرة أخرى.',
  ]);
}

class GenericAttendanceFailure extends AttendanceFailure {
  const GenericAttendanceFailure([
    super.message = 'تعذر تنفيذ عملية الحضور. حاول مرة أخرى.',
  ]);
}

AttendanceFailure mapExceptionToAttendanceFailure(Object error) {
  if (error is AttendanceFailure) {
    return error;
  }
  if (isPermissionDeniedException(error)) {
    return const AttendancePermissionDeniedFailure();
  }
  if (isNotFoundException(error)) {
    return const AttendanceSessionNotFoundFailure();
  }
  return const GenericAttendanceFailure();
}

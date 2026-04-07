import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:equatable/equatable.dart';

sealed class AttendanceSessionAdminState extends Equatable {
  const AttendanceSessionAdminState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class AttendanceSessionAdminInitial extends AttendanceSessionAdminState {
  const AttendanceSessionAdminInitial();
}

final class AttendanceSessionAdminLoading extends AttendanceSessionAdminState {
  const AttendanceSessionAdminLoading();
}

final class AttendanceSessionAdminSuccess extends AttendanceSessionAdminState {
  const AttendanceSessionAdminSuccess({
    required this.session,
    required this.message,
  });

  final AttendanceSession session;
  final String message;

  @override
  List<Object?> get props => [session, message];
}

final class AttendanceSessionAdminError extends AttendanceSessionAdminState {
  const AttendanceSessionAdminError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

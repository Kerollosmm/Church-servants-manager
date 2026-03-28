import 'dart:async';

import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/student_attendance_history_item.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/student_attendance/student_attendance_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/student_attendance/student_attendance_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAttendanceRepository extends Mock implements IAttendanceRepository {}

void main() {
  late MockAttendanceRepository repository;
  late StudentAttendanceCubit cubit;
  late StreamController<List<StudentAttendanceHistoryItem>> controller;

  StudentAttendanceHistoryItem item({
    required String sessionId,
    required AttendanceEffectiveStatus status,
  }) {
    return StudentAttendanceHistoryItem(
      sessionId: sessionId,
      teamId: 'team-1',
      teamNameSnapshot: 'Team One',
      title: 'Weekly',
      dateKey: '2026-03-28',
      sessionStartsAt: DateTime(2026, 3, 28, 10),
      sessionEndsAt: DateTime(2026, 3, 28, 11),
      effectiveStatus: status,
      isSessionClosed: true,
    );
  }

  setUp(() {
    repository = MockAttendanceRepository();
    controller =
        StreamController<List<StudentAttendanceHistoryItem>>.broadcast();
    cubit = StudentAttendanceCubit(repository: repository);

    when(
      () => repository.watchStudentAttendanceHistory(
        studentId: 'student-1',
        teamId: 'team-1',
      ),
    ).thenAnswer((_) => controller.stream);
  });

  tearDown(() async {
    await cubit.close();
    await controller.close();
  });

  test('load computes mixed attendance stats correctly', () async {
    final states = <StudentAttendanceState>[];
    final subscription = cubit.stream.listen(states.add);

    cubit.load('student-1', teamId: 'team-1');
    controller.add([
      item(sessionId: 'session-1', status: AttendanceEffectiveStatus.present),
      item(sessionId: 'session-2', status: AttendanceEffectiveStatus.late),
      item(sessionId: 'session-3', status: AttendanceEffectiveStatus.absent),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(states.first, const StudentAttendanceLoading());
    expect(cubit.state, isA<StudentAttendanceLoaded>());

    final loaded = cubit.state as StudentAttendanceLoaded;
    expect(loaded.items, hasLength(3));
    expect(loaded.total, 3);
    expect(loaded.attended, 2);
    expect(loaded.percentage, closeTo(66.6667, 0.01));

    await subscription.cancel();
  });
}

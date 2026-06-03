import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_enums.dart';
import 'package:church_management_system/features/attendance/domain/entities/student_attendance_history_item.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/student_attendance/student_attendance_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/student_attendance/student_attendance_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

void main() {
  late MockAttendanceRepository repository;

  setUp(() {
    repository = MockAttendanceRepository();
  });

  test('loadForStudent emits stats from history', () async {
    when(
      () => repository.getStudentAttendanceHistory(
        studentId: 'student-1',
        teamId: 'team-1',
      ),
    ).thenAnswer(
      (_) async => [
        StudentAttendanceHistoryItem(
          sessionId: 'session-1',
          teamId: 'team-1',
          teamNameSnapshot: 'Team A',
          title: 'Session 1',
          dateKey: '2026-03-09',
          sessionStartsAt: DateTime(2026, 3, 9, 18),
          sessionEndsAt: DateTime(2026, 3, 9, 18, 30),
          effectiveStatus: AttendanceEffectiveStatus.present,
          isSessionClosed: true,
        ),
        StudentAttendanceHistoryItem(
          sessionId: 'session-2',
          teamId: 'team-1',
          teamNameSnapshot: 'Team A',
          title: 'Session 2',
          dateKey: '2026-03-10',
          sessionStartsAt: DateTime(2026, 3, 10, 18),
          sessionEndsAt: DateTime(2026, 3, 10, 18, 30),
          effectiveStatus: AttendanceEffectiveStatus.late,
          isSessionClosed: true,
        ),
        StudentAttendanceHistoryItem(
          sessionId: 'session-3',
          teamId: 'team-1',
          teamNameSnapshot: 'Team A',
          title: 'Session 3',
          dateKey: '2026-03-11',
          sessionStartsAt: DateTime(2026, 3, 11, 18),
          sessionEndsAt: DateTime(2026, 3, 11, 18, 30),
          effectiveStatus: AttendanceEffectiveStatus.absent,
          isSessionClosed: true,
        ),
      ],
    );

    final cubit = StudentAttendanceCubit(repository: repository);
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<StudentAttendanceLoading>(),
        isA<StudentAttendanceLoaded>()
            .having((state) => state.stats.presentCount, 'present', 1)
            .having((state) => state.stats.lateCount, 'late', 1)
            .having((state) => state.stats.absentCount, 'absent', 1),
      ]),
    );

    await cubit.loadForStudent(studentId: 'student-1', teamId: 'team-1');
    await expectation;
    await cubit.close();
  });
}

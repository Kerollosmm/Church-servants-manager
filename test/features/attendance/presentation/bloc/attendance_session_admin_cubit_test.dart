import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_state.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAttendanceRepository extends Mock implements IAttendanceRepository {}

void main() {
  late MockAttendanceRepository repository;

  final admin = const AuthUser(
    uid: 'admin-1',
    email: 'admin@example.com',
    name: 'Admin',
    role: UserRole.admin,
    isEmailVerified: true,
  );

  final session = AttendanceSession(
    id: 'session-1',
    teamId: 'team-1',
    teamNameSnapshot: 'Team A',
    title: 'Wednesday',
    dateKey: '2026-03-09',
    startsAt: DateTime(2026, 3, 9, 18, 0),
    endsAt: DateTime(2026, 3, 9, 18, 30),
    durationMinutes: 30,
    createdByUserId: admin.uid,
    createdByName: admin.name,
    createdAt: DateTime(2026, 3, 9, 18, 0),
    updatedAt: DateTime(2026, 3, 9, 18, 0),
  );

  setUp(() {
    repository = MockAttendanceRepository();
  });

  test('createSession emits loading then success', () async {
    when(
      () => repository.createSession(
        teamId: 'team-1',
        teamNameSnapshot: 'Team A',
        startsAt: DateTime(2026, 3, 9, 18, 0),
        durationMinutes: 30,
        createdBy: admin,
        title: 'Wednesday',
      ),
    ).thenAnswer((_) async => session);

    final cubit = AttendanceSessionAdminCubit(repository: repository);
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<AttendanceSessionAdminLoading>(),
        isA<AttendanceSessionAdminSuccess>().having(
          (state) => state.session.id,
          'session.id',
          'session-1',
        ),
      ]),
    );

    await cubit.createSession(
      actor: admin,
      teamId: 'team-1',
      teamNameSnapshot: 'Team A',
      startsAt: DateTime(2026, 3, 9, 18, 0),
      durationMinutes: 30,
      title: 'Wednesday',
    );

    await expectation;
    await cubit.close();
  });

  test('createSession emits validation error for invalid duration', () async {
    final cubit = AttendanceSessionAdminCubit(repository: repository);

    await cubit.createSession(
      actor: admin,
      teamId: 'team-1',
      teamNameSnapshot: 'Team A',
      startsAt: DateTime(2026, 3, 9, 18, 0),
      durationMinutes: 0,
      title: 'Wednesday',
    );

    expect(cubit.state, isA<AttendanceSessionAdminError>());
    verifyNever(
      () => repository.createSession(
        teamId: 'team-1',
        teamNameSnapshot: 'Team A',
        startsAt: DateTime(2026, 3, 9, 18, 0),
        durationMinutes: 0,
        createdBy: admin,
        title: 'Wednesday',
      ),
    );
    await cubit.close();
  });
}

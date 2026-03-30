import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/routing/app_router.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_history/attendance_history_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_cubit.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockAttendanceRepository extends Mock implements IAttendanceRepository {}

void main() {
  final getIt = GetIt.instance;

  setUp(() {
    getIt.registerFactory<AttendanceSessionAdminCubit>(
      () => AttendanceSessionAdminCubit(repository: MockAttendanceRepository()),
    );
    getIt.registerFactory<AttendanceHistoryCubit>(
      () => AttendanceHistoryCubit(repository: MockAttendanceRepository()),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  test('attendanceSessionCreate route resolves with injected cubit', () {
    final router = AppRouter();
    final route = router.onGenerateRoute(
      const RouteSettings(name: attendanceSessionCreate),
    );

    expect(route, isA<MaterialPageRoute<dynamic>>());
  });

  test('attendanceHistory route resolves with injected cubit', () {
    final router = AppRouter();
    final route = router.onGenerateRoute(
      const RouteSettings(name: attendanceHistory),
    );

    expect(route, isA<MaterialPageRoute<dynamic>>());
  });
}

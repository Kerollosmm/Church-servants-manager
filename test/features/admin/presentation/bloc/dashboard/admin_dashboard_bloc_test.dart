import 'package:church_management_system/features/admin/data/services/admin_statistics_service.dart';
import 'package:church_management_system/features/admin/presentation/bloc/dashboard/admin_dashboard_bloc.dart';
import 'package:church_management_system/features/admin/presentation/bloc/dashboard/admin_dashboard_event.dart';
import 'package:church_management_system/features/admin/presentation/bloc/dashboard/admin_dashboard_state.dart';
import 'package:church_management_system/features/servant/domain/repos/i_servant_repository.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/domain/repos/i_team_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIStudentRepository extends Mock implements IStudentRepository {}
class MockIServantRepository extends Mock implements IServantRepository {}
class MockITeamRepository extends Mock implements ITeamRepository {}
class MockAdminStatisticsService extends Mock implements AdminStatisticsService {}

void main() {
  late MockIStudentRepository mockStudentRepo;
  late MockIServantRepository mockServantRepo;
  late MockITeamRepository mockTeamRepo;
  late MockAdminStatisticsService mockStatsService;
  late AdminDashboardBloc bloc;

  setUp(() {
    mockStudentRepo = MockIStudentRepository();
    mockServantRepo = MockIServantRepository();
    mockTeamRepo = MockITeamRepository();
    mockStatsService = MockAdminStatisticsService();
    bloc = AdminDashboardBloc(
      mockStudentRepo,
      mockServantRepo,
      mockTeamRepo,
      mockStatsService,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('AdminDashboardBloc', () {
    test('initial state is AdminDashboardInitial', () {
      expect(bloc.state, isA<AdminDashboardInitial>());
    });

    final defaultStats = GlobalDashboardStats(
      totalSessions: 10,
      totalPresent: 80,
      totalRosterEntries: 100,
      updatedAt: DateTime(2026),
    );

    final emptyStats = GlobalDashboardStats(
      totalSessions: 0,
      totalPresent: 0,
      totalRosterEntries: 0,
      updatedAt: DateTime(2026),
    );

    void setupSuccessPaths({GlobalDashboardStats? stats}) {
      when(() => mockStudentRepo.getAllStudents(includeArchived: false))
          .thenAnswer((_) async => <StudentModel>[]);
      when(() => mockServantRepo.getAllServants()).thenAnswer((_) async => []);
      when(() => mockTeamRepo.getAllTeams(includeArchived: false))
          .thenAnswer((_) async => <TeamModel>[]);
      when(
        () => mockStatsService.getGlobalDashboardStats(forceRefresh: any(named: 'forceRefresh')),
      ).thenAnswer((_) async => stats ?? defaultStats);
    }

    test('emits [AdminDashboardLoading, AdminDashboardLoaded] on LoadDashboardData success', () async {
      setupSuccessPaths();
      
      final expectedStates = [
        isA<AdminDashboardLoading>(),
        isA<AdminDashboardLoaded>()
          .having((s) => s.kpiData.totalStudents, 'totalStudents', 0)
          .having((s) => s.kpiData.attendanceRate, 'attendanceRate', 80.0),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(const LoadDashboardData());
    });

    test('Attendance rate calculation - handles zero roster entries (avoid div by zero)', () async {
      setupSuccessPaths(stats: emptyStats);

      final expectedStates = [
        isA<AdminDashboardLoading>(),
        isA<AdminDashboardLoaded>().having((s) => s.kpiData.attendanceRate, 'attendanceRate', 0.0),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(const LoadDashboardData());
    });

    test('Attendance rate calculation - clamps rate to 100%', () async {
      setupSuccessPaths(
        stats: GlobalDashboardStats(
          totalSessions: 1,
          totalPresent: 150,
          totalRosterEntries: 100,
          updatedAt: DateTime.now(),
        ),
      );

      final expectedStates = [
        isA<AdminDashboardLoading>(),
        isA<AdminDashboardLoaded>().having((s) => s.kpiData.attendanceRate, 'attendanceRate', 100.0),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(const LoadDashboardData());
    });

    test('Stats Fallback: when getGlobalDashboardStats throws, uses default zeros instead of crashing', () async {
      when(() => mockStudentRepo.getAllStudents(includeArchived: false))
          .thenAnswer((_) async => <StudentModel>[]);
      when(() => mockServantRepo.getAllServants()).thenAnswer((_) async => []);
      when(() => mockTeamRepo.getAllTeams(includeArchived: false))
          .thenAnswer((_) async => <TeamModel>[]);
      when(
        () => mockStatsService.getGlobalDashboardStats(forceRefresh: true),
      ).thenAnswer((_) => Future.error(Exception('Firestore aggregate error')));

      final expectedStates = [
        isA<AdminDashboardLoading>(),
        isA<AdminDashboardLoaded>()
            .having((s) => s.kpiData.totalSessions, 'totalSessions', 0)
            .having((s) => s.kpiData.totalPresent, 'totalPresent', 0)
            .having((s) => s.kpiData.attendanceRate, 'attendanceRate', 0.0),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(const LoadDashboardData());
    });

    test('Repository Failure: emits AdminDashboardError if a critical repo fails', () async {
      when(() => mockStudentRepo.getAllStudents(includeArchived: false))
          .thenAnswer((_) => Future.error(Exception('Student repo error')));
      when(() => mockServantRepo.getAllServants()).thenAnswer((_) async => []);
      when(() => mockTeamRepo.getAllTeams(includeArchived: false))
          .thenAnswer((_) async => <TeamModel>[]);
      when(
        () => mockStatsService.getGlobalDashboardStats(forceRefresh: true),
      ).thenAnswer((_) async => defaultStats);

      final expectedStates = [
        isA<AdminDashboardLoading>(),
        isA<AdminDashboardError>().having(
          (s) => s.message,
          'message',
          contains('تعذر تحميل'),
        ),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(const LoadDashboardData());
    });
  });
}

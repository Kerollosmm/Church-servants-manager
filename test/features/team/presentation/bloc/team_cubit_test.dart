import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:church_management_system/features/team/presentation/bloc/team_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTeamRepository extends Mock implements TeamRepository {}

class MockAdminTeamService extends Mock implements AdminTeamService {}

void main() {
  late MockTeamRepository repository;
  late MockAdminTeamService adminService;

  final admin = AuthUser(
    uid: 'admin1',
    email: 'admin@example.com',
    name: 'Admin',
    role: UserRole.admin,
    isEmailVerified: true,
  );

  final team = TeamModel(id: 't1', name: 'Team A', groupId: 'year1');
  final servant = ServantModel(docID: 's1', uid: 's1', name: 'Servant A');

  setUp(() {
    repository = MockTeamRepository();
    adminService = MockAdminTeamService();
  });

  test('loadTeamsByGroup emits loading then loaded', () async {
    when(
      () => repository.getTeamsByGroup('year1', includeArchived: false),
    ).thenAnswer((_) async => [team]);

    final cubit = TeamCubit(
      teamRepository: repository,
      adminTeamService: adminService,
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<TeamLoading>(),
        isA<TeamLoaded>().having((s) => s.teams.length, 'count', 1),
      ]),
    );

    await cubit.loadTeamsByGroup('year1');
    await expectation;
    await cubit.close();
  });

  test('assignServant emits team error when admin service fails', () async {
    when(
      () => adminService.assignServantToTeam(
        actor: admin,
        team: team,
        servant: servant,
      ),
    ).thenThrow(StateError('permission denied'));

    final cubit = TeamCubit(
      teamRepository: repository,
      adminTeamService: adminService,
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<TeamLoading>(),
        isA<TeamError>().having(
          (s) => s.message,
          'message',
          'تعذر تعيين الخادم. حاول مرة أخرى.',
        ),
      ]),
    );

    await cubit.assignServant(actor: admin, team: team, servant: servant);
    await expectation;
    await cubit.close();
  });

  test('createTeam emits success then reloads group teams', () async {
    when(() => repository.createTeam(team)).thenAnswer((_) async => 't2');
    when(
      () => repository.getTeamsByGroup('year1', includeArchived: false),
    ).thenAnswer((_) async => [team]);

    final cubit = TeamCubit(
      teamRepository: repository,
      adminTeamService: adminService,
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<TeamLoading>(),
        isA<TeamLoaded>()
            .having((s) => s.teams.length, 'count', 1)
            .having(
              (s) => s.mutationStatus,
              'mutationStatus',
              TeamMutationStatus.success,
            )
            .having(
              (s) => s.feedbackMessage,
              'feedbackMessage',
              'تم إنشاء الفريق بنجاح',
            ),
      ]),
    );

    await cubit.createTeam(team);
    await expectation;
    verify(() => repository.createTeam(team)).called(1);
    verify(
      () => repository.getTeamsByGroup('year1', includeArchived: false),
    ).called(1);
    await cubit.close();
  });

  test(
    'mutation preserves loaded teams while reporting in-progress and success',
    () async {
      when(
        () => repository.getTeamsByGroup('year1', includeArchived: false),
      ).thenAnswer((_) async => [team]);
      when(() => repository.updateTeam(team)).thenAnswer((_) async {});

      final cubit = TeamCubit(
        teamRepository: repository,
        adminTeamService: adminService,
      );

      await cubit.loadTeamsByGroup('year1');

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<TeamLoaded>().having(
            (s) => s.mutationStatus,
            'mutationStatus',
            TeamMutationStatus.inProgress,
          ),
          isA<TeamLoaded>()
              .having((s) => s.teams.length, 'count', 1)
              .having(
                (s) => s.mutationStatus,
                'mutationStatus',
                TeamMutationStatus.success,
              )
              .having(
                (s) => s.feedbackMessage,
                'feedbackMessage',
                'تم تحديث الفريق بنجاح',
              ),
        ]),
      );

      await cubit.updateTeam(team);
      await expectation;
      verify(() => repository.updateTeam(team)).called(1);
      verify(
        () => repository.getTeamsByGroup('year1', includeArchived: false),
      ).called(2);
      await cubit.close();
    },
  );

  test('setTeamMembers emits team error when service fails', () async {
    when(
      () => adminService.setStudentsForTeam(
        actor: admin,
        team: team,
        selectedStudents: const [],
      ),
    ).thenThrow(StateError('failed update members'));

    final cubit = TeamCubit(
      teamRepository: repository,
      adminTeamService: adminService,
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<TeamLoading>(),
        isA<TeamError>().having(
          (s) => s.message,
          'message',
          'تعذر تحديث أعضاء الفريق. حاول مرة أخرى.',
        ),
      ]),
    );

    await cubit.setTeamMembers(actor: admin, team: team, students: const []);
    await expectation;
    await cubit.close();
  });
}

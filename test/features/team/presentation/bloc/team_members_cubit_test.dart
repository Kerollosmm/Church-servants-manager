import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/presentation/bloc/team_members_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStudentDataRepository extends Mock implements StudentDataRepository {}

class MockAdminTeamService extends Mock implements AdminTeamService {}

void main() {
  late MockStudentDataRepository repository;
  late MockAdminTeamService adminTeamService;

  final admin = const AuthUser(
    uid: 'admin-1',
    email: 'admin@example.com',
    name: 'Admin',
    role: UserRole.admin,
    isEmailVerified: true,
  );

  final team = TeamModel(id: 'team-a', name: 'Team A', groupId: 'year1');

  StudentModel student({
    required String id,
    required String name,
    String? classId,
  }) {
    return StudentModel(
      uid: id,
      docID: id,
      name: name,
      imageUrl: null,
      role: UserRole.student,
      mobile: '01234567890',
      group: Group.year1,
      teamName: 'Team A',
      motherPhone: '',
      fatherPhone: '',
      grade: 1,
      educationStage: EducationStage.preparatory,
      school: null,
      address: null,
      birthdate: null,
      fatherOfConfession: '',
      notes: null,
      classId: classId,
    );
  }

  setUp(() {
    repository = MockStudentDataRepository();
    adminTeamService = MockAdminTeamService();
  });

  test('load seeds selection from assigned team membership', () async {
    when(() => repository.getStudentsByGroupWithFallback('year1')).thenAnswer(
      (_) async => (
        students: [
          student(id: 's1', name: 'Andrew', classId: 'team-a'),
          student(id: 's2', name: 'Mina'),
        ],
        isFromCache: false,
      ),
    );

    final cubit = TeamMembersCubit(
      studentRepository: repository,
      adminTeamService: adminTeamService,
    );
    await cubit.load(groupId: 'year1', teamId: 'team-a');

    expect(cubit.state.students.length, 2);
    expect(cubit.state.selectedStudentIds, {'s1'});
    expect(cubit.state.visibleStudents.length, 2);
    await cubit.close();
  });

  test('search and toggleSelection update visible state locally', () async {
    when(() => repository.getStudentsByGroupWithFallback('year1')).thenAnswer(
      (_) async => (
        students: [
          student(id: 's1', name: 'Andrew'),
          student(id: 's2', name: 'Mina'),
        ],
        isFromCache: true,
      ),
    );

    final cubit = TeamMembersCubit(
      studentRepository: repository,
      adminTeamService: adminTeamService,
    );
    await cubit.load(groupId: 'year1', teamId: 'team-a');

    cubit.search('and');
    expect(cubit.state.visibleStudents.map((s) => s.docID).toList(), ['s1']);

    cubit.toggleSelection('s2', true);
    expect(cubit.state.selectedStudentIds.contains('s2'), isTrue);
    expect(cubit.selectedStudents().map((s) => s.docID).toSet(), {'s2'});
    await cubit.close();
  });

  test('saveMembers emits success feedback after successful update', () async {
    final selectedStudents = [
      student(id: 's1', name: 'Andrew', classId: 'team-a'),
    ];
    when(() => repository.getStudentsByGroupWithFallback('year1')).thenAnswer(
      (_) async => (
        students: selectedStudents,
        isFromCache: false,
      ),
    );
    when(
      () => adminTeamService.setStudentsForTeam(
        actor: admin,
        team: team,
        selectedStudents: selectedStudents,
      ),
    ).thenAnswer((_) async {});

    final cubit = TeamMembersCubit(
      studentRepository: repository,
      adminTeamService: adminTeamService,
    );
    await cubit.load(groupId: 'year1', teamId: 'team-a');

    await cubit.saveMembers(actor: admin, team: team);

    expect(cubit.state.isSaving, isFalse);
    expect(cubit.state.mutationStatus, TeamMembersMutationStatus.success);
    expect(cubit.state.feedbackMessage, 'تم تحديث أعضاء الفريق بنجاح');
    await cubit.close();
  });

  test('saveMembers emits failure feedback when update fails', () async {
    final selectedStudents = [
      student(id: 's1', name: 'Andrew', classId: 'team-a'),
    ];
    when(() => repository.getStudentsByGroupWithFallback('year1')).thenAnswer(
      (_) async => (
        students: selectedStudents,
        isFromCache: false,
      ),
    );
    when(
      () => adminTeamService.setStudentsForTeam(
        actor: admin,
        team: team,
        selectedStudents: selectedStudents,
      ),
    ).thenThrow(Exception('boom'));

    final cubit = TeamMembersCubit(
      studentRepository: repository,
      adminTeamService: adminTeamService,
    );
    await cubit.load(groupId: 'year1', teamId: 'team-a');

    await cubit.saveMembers(actor: admin, team: team);

    expect(cubit.state.isSaving, isFalse);
    expect(cubit.state.mutationStatus, TeamMembersMutationStatus.failure);
    expect(cubit.state.feedbackMessage, 'تعذر تحديث أعضاء الفريق. حاول مرة أخرى.');
    await cubit.close();
  });
}

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_list_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIStudentRepository extends Mock implements IStudentRepository {}

void main() {
  late MockIStudentRepository repository;
  late GetStudentsListUseCase useCase;

  setUp(() {
    repository = MockIStudentRepository();
    useCase = GetStudentsListUseCase(repository);
  });

  group('GetStudentsListUseCase', () {
    final tStudent = StudentModel(
      uid: '1',
      docID: '1',
      name: 'Test Student',
      imageUrl: null,
      role: UserRole.student,
      mobile: '01234567890',
      group: Group.year1,
      teamName: 'Team A',
      motherPhone: '01234567890',
      fatherPhone: '01234567890',
      grade: 1,
      educationStage: EducationStage.preparatory,
      school: null,
      address: null,
      birthdate: null,
      fatherOfConfession: 'Fr. Test',
      notes: null,
      classId: 'team1',
    );

    final tStudentsList = [tStudent];

    test('should return null if actor is archived', () async {
      final actor = AuthUser(
        uid: '1',
        email: 'test@example.com',
        name: 'Archived User',
        role: UserRole.admin,
        isArchived: true,
      );

      final result = await useCase(actor: actor);

      expect(result, isNull);
      verifyZeroInteractions(repository);
    });

    group('Admin Role', () {
      final adminActor = AuthUser(
        uid: '1',
        email: 'admin@example.com',
        name: 'Admin',
        role: UserRole.admin,
      );

      test('should call getAllStudents when teamId is null', () async {
        when(
          () => repository.getAllStudents(limit: 50, includeArchived: false),
        ).thenAnswer((_) async => tStudentsList);

        final result = await useCase(actor: adminActor);

        expect(result, equals(tStudentsList));
        verify(
          () => repository.getAllStudents(limit: 50, includeArchived: false),
        ).called(1);
        verifyNoMoreInteractions(repository);
      });

      test('should call getAllStudents when teamId is empty', () async {
        when(
          () => repository.getAllStudents(limit: 50, includeArchived: false),
        ).thenAnswer((_) async => tStudentsList);

        final result = await useCase(actor: adminActor, teamId: '');

        expect(result, equals(tStudentsList));
        verify(
          () => repository.getAllStudents(limit: 50, includeArchived: false),
        ).called(1);
        verifyNoMoreInteractions(repository);
      });

      test('should call getStudentsByClass when teamId is provided', () async {
        final teamId = 'team1';
        when(
          () => repository.getStudentsByClass(teamId, includeArchived: false),
        ).thenAnswer((_) async => tStudentsList);

        final result = await useCase(actor: adminActor, teamId: teamId);

        expect(result, equals(tStudentsList));
        verify(
          () => repository.getStudentsByClass(teamId, includeArchived: false),
        ).called(1);
        verifyNoMoreInteractions(repository);
      });
    });

    group('Servant Role', () {
      test(
        'should call getStudentsByClass if teamId matches assignedTeamIds',
        () async {
          final servantActor = AuthUser(
            uid: '2',
            email: 'servant@example.com',
            name: 'Servant',
            role: UserRole.servant,
            assignedTeamIds: ['team1', 'team2'],
          );

          final teamId = 'team2';
          when(
            () => repository.getStudentsByClass(teamId, includeArchived: false),
          ).thenAnswer((_) async => tStudentsList);

          final result = await useCase(actor: servantActor, teamId: teamId);

          expect(result, equals(tStudentsList));
          verify(
            () => repository.getStudentsByClass(teamId, includeArchived: false),
          ).called(1);
          verifyNoMoreInteractions(repository);
        },
      );

      test(
        'should return null if teamId does not match assignedTeamIds',
        () async {
          final servantActor = AuthUser(
            uid: '2',
            email: 'servant@example.com',
            name: 'Servant',
            role: UserRole.servant,
            assignedTeamIds: ['team1', 'team2'],
          );

          final teamId = 'team3';

          final result = await useCase(actor: servantActor, teamId: teamId);

          expect(result, isNull);
          verifyZeroInteractions(repository);
        },
      );

      test(
        'should call getStudentsByClass if no teamId provided and only 1 assignedTeamId',
        () async {
          final servantActor = AuthUser(
            uid: '2',
            email: 'servant@example.com',
            name: 'Servant',
            role: UserRole.servant,
            assignedTeamIds: ['team1'],
          );

          when(
            () =>
                repository.getStudentsByClass('team1', includeArchived: false),
          ).thenAnswer((_) async => tStudentsList);

          final result = await useCase(actor: servantActor);

          expect(result, equals(tStudentsList));
          verify(
            () =>
                repository.getStudentsByClass('team1', includeArchived: false),
          ).called(1);
          verifyNoMoreInteractions(repository);
        },
      );

      test(
        'should call getStudentsByClasses if no teamId provided and >1 assignedTeamId',
        () async {
          final servantActor = AuthUser(
            uid: '2',
            email: 'servant@example.com',
            name: 'Servant',
            role: UserRole.servant,
            assignedTeamIds: ['team1', 'team2'],
          );

          when(
            () => repository.getStudentsByClasses([
              'team1',
              'team2',
            ], includeArchived: false),
          ).thenAnswer((_) async => tStudentsList);

          final result = await useCase(actor: servantActor);

          expect(result, equals(tStudentsList));
          verify(
            () => repository.getStudentsByClasses([
              'team1',
              'team2',
            ], includeArchived: false),
          ).called(1);
          verifyNoMoreInteractions(repository);
        },
      );

      test(
        'should call getStudentsByGroup if assignedTeamIds is empty but groupId is provided',
        () async {
          final servantActor = AuthUser(
            uid: '2',
            email: 'servant@example.com',
            name: 'Servant',
            role: UserRole.servant,
            assignedTeamIds: [],
            groupId: 'group1',
          );

          when(
            () =>
                repository.getStudentsByGroup('group1', includeArchived: false),
          ).thenAnswer((_) async => tStudentsList);

          final result = await useCase(actor: servantActor);

          expect(result, equals(tStudentsList));
          verify(
            () =>
                repository.getStudentsByGroup('group1', includeArchived: false),
          ).called(1);
          verifyNoMoreInteractions(repository);
        },
      );

      test(
        'should return null if assignedTeamIds is empty and groupId is empty/null',
        () async {
          final servantActor = AuthUser(
            uid: '2',
            email: 'servant@example.com',
            name: 'Servant',
            role: UserRole.servant,
            assignedTeamIds: [],
          );

          final result = await useCase(actor: servantActor);

          expect(result, isNull);
          verifyZeroInteractions(repository);
        },
      );
    });

    group('Student Role', () {
      test('should return null', () async {
        final studentActor = AuthUser(
          uid: '3',
          email: 'student@example.com',
          name: 'Student',
          role: UserRole.student,
        );

        final result = await useCase(actor: studentActor);

        expect(result, isNull);
        verifyZeroInteractions(repository);
      });
    });
  });
}

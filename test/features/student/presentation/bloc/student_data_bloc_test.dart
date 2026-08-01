import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/student/domain/entities/student.dart';
import 'package:church_management_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_list_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/provision_student_invitation_usecase.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStudentDataRepository extends Mock implements StudentDataRepository {}

class MockGetStudentsListUseCase extends Mock
    implements GetStudentsListUseCase {}

class MockCanMutateStudentUseCase extends Mock
    implements CanMutateStudentUseCase {}

class MockProvisionStudentInvitationUseCase extends Mock
    implements ProvisionStudentInvitationUseCase {}

void main() {
  late MockStudentDataRepository repository;
  late MockGetStudentsListUseCase getStudentsList;
  late MockCanMutateStudentUseCase canMutateStudent;
  late MockProvisionStudentInvitationUseCase provisionUseCase;

  AuthUser actor(UserRole role) => AuthUser(
    uid: 'u1',
    email: 'user@example.com',
    name: 'User',
    role: role,
    isEmailVerified: true,
    groupId: 'year1',
  );

  Student student({String id = 's1', UserRole role = UserRole.student}) {
    return StudentModel(
      uid: id,
      docID: id,
      name: 'Student $id',
      imageUrl: null,
      role: role,
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
      fatherOfConfession: 'Fr.',
      notes: null,
      classId: 'team1',
    ).toDomain();
  }

  setUpAll(() {
    registerFallbackValue(student());
    registerFallbackValue(UserRole.student);
  });

  setUp(() {
    repository = MockStudentDataRepository();
    getStudentsList = MockGetStudentsListUseCase();
    canMutateStudent = MockCanMutateStudentUseCase();
    provisionUseCase = MockProvisionStudentInvitationUseCase();
  });

  test(
    'load emits loading then empty loaded when actor has no stream access',
    () async {
      final admin = actor(UserRole.admin);
      when(
        () => getStudentsList.call(actor: admin),
      ).thenAnswer((_) async => null);

      final bloc = StudentDataBloc(
        studentRepository: repository,
        getStudentsList: getStudentsList,
        canMutateStudent: canMutateStudent,
        provisionUseCase: provisionUseCase,
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<StudentDataLoading>()
              .having((s) => s.previousStudents.length, 'previousStudents', 0)
              .having((s) => s.isRefresh, 'isRefresh', false),
          isA<StudentDataLoaded>().having((s) => s.students.length, 'count', 0),
        ]),
      );

      bloc.add(StudentsLoadRequested(actor: admin));
      await expectation;
      await bloc.close();
    },
  );

  test(
    'search with changed team reloads the student stream for the new team',
    () async {
      final admin = actor(UserRole.admin);

      when(
        () => getStudentsList.call(
          actor: admin,
          teamId: 'team1',
          includeArchived: any(named: 'includeArchived'),
        ),
      ).thenAnswer((_) async => [student()]);

      when(
        () => getStudentsList.call(
          actor: admin,
          teamId: 'team2',
          includeArchived: any(named: 'includeArchived'),
        ),
      ).thenAnswer((_) async => [student(id: 's2')]);

      final bloc = StudentDataBloc(
        studentRepository: repository,
        getStudentsList: getStudentsList,
        canMutateStudent: canMutateStudent,
        provisionUseCase: provisionUseCase,
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<StudentDataLoading>(),
          isA<StudentDataLoaded>().having(
            (s) => s.currentFilterTeamId,
            'team',
            'team1',
          ),
          isA<StudentDataLoading>(),
          isA<StudentDataLoaded>()
              .having((s) => s.currentFilterTeamId, 'team', 'team2')
              .having((s) => s.students.single.docID, 'student', 's2'),
        ]),
      );

      bloc.add(StudentsLoadRequested(actor: admin, teamId: 'team1'));
      await Future<void>.delayed(Duration.zero);

      bloc.add(
        StudentsSearchRequested(actor: admin, query: '', teamId: 'team2'),
      );
      await Future<void>.delayed(Duration.zero);

      await expectation;
      await bloc.close();
    },
  );

  test('create emits not-allowed when actor cannot mutate student', () async {
    final servant = actor(UserRole.servant);
    final newStudent = student();
    when(
      () => canMutateStudent.canCreate(servant, newStudent),
    ).thenReturn(false);

    final bloc = StudentDataBloc(
      studentRepository: repository,
      getStudentsList: getStudentsList,
      canMutateStudent: canMutateStudent,
      provisionUseCase: provisionUseCase,
    );

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<StudentDataError>().having((s) => s.message, 'message', isNotEmpty),
      ]),
    );

    bloc.add(StudentCreated(actor: servant, student: newStudent));
    await expectation;
    verifyNever(() => repository.createStudent(newStudent));
    await bloc.close();
  });

  test('update emits not found when target student does not exist', () async {
    final admin = actor(UserRole.admin);
    final updated = student(id: 'missing');

    when(() => repository.getStudentById(any())).thenAnswer((_) async => null);

    final bloc = StudentDataBloc(
      studentRepository: repository,
      getStudentsList: getStudentsList,
      canMutateStudent: canMutateStudent,
      provisionUseCase: provisionUseCase,
    );

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<StudentDataError>().having((s) => s.message, 'message', isNotEmpty),
      ]),
    );

    bloc.add(StudentUpdated(actor: admin, student: updated));
    await expectation;
    verify(() => repository.getStudentById(any())).called(1);
    await bloc.close();
  });

  test('update denies role change when actor is not admin', () async {
    final servantActor = actor(UserRole.servant);
    final existing = student();
    final updated = student(role: UserRole.servant);

    when(
      () => repository.getStudentById('s1'),
    ).thenAnswer((_) async => existing);
    when(
      () => canMutateStudent.canUpdate(servantActor, existing, updated),
    ).thenReturn(true);

    final bloc = StudentDataBloc(
      studentRepository: repository,
      getStudentsList: getStudentsList,
      canMutateStudent: canMutateStudent,
      provisionUseCase: provisionUseCase,
    );

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<StudentDataError>().having((s) => s.message, 'message', isNotEmpty),
      ]),
    );

    bloc.add(StudentUpdated(actor: servantActor, student: updated));
    await expectation;
    verifyNever(
      () => repository.updateStudentAndSyncLinkedUserRole(
        updatedStudent: updated,
        previousRole: UserRole.student,
      ),
    );
    await bloc.close();
  });

  test('update rejects servant promotion when linked uid is empty', () async {
    final adminActor = actor(UserRole.admin);
    final existing = student(id: 's2');
    final updated = existing.copyWith(uid: '   ', role: UserRole.servant);

    when(
      () => repository.getStudentById('s2'),
    ).thenAnswer((_) async => existing);
    when(
      () => canMutateStudent.canUpdate(adminActor, existing, updated),
    ).thenReturn(true);

    final bloc = StudentDataBloc(
      studentRepository: repository,
      getStudentsList: getStudentsList,
      canMutateStudent: canMutateStudent,
      provisionUseCase: provisionUseCase,
    );

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<StudentDataError>().having((s) => s.message, 'message', isNotEmpty),
      ]),
    );

    bloc.add(StudentUpdated(actor: adminActor, student: updated));
    await expectation;
    verifyNever(() => repository.updateStudent(any()));
    verifyNever(
      () => repository.updateStudentAndSyncLinkedUserRole(
        updatedStudent: updated,
        previousRole: UserRole.student,
      ),
    );
    await bloc.close();
  });

  test('create calls provisionUseCase when credentials provided', () async {
    final admin = actor(UserRole.admin);
    final newStudent = student(id: 'local-id');

    when(() => canMutateStudent.canCreate(admin, newStudent)).thenReturn(true);
    when(
      () => provisionUseCase(
        student: newStudent,
        email: any(named: 'email'),
      ),
    ).thenAnswer((_) async => 'auth-uid');

    final bloc = StudentDataBloc(
      studentRepository: repository,
      getStudentsList: getStudentsList,
      canMutateStudent: canMutateStudent,
      provisionUseCase: provisionUseCase,
    );

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<StudentDataLoaded>().having(
          (s) => s.mutationStatus,
          'mutationStatus',
          StudentMutationStatus.success,
        ),
      ]),
    );

    bloc.add(
      StudentCreated(
        actor: admin,
        student: newStudent,
        email: 'student@example.com',
      ),
    );

    await expectation;
    verify(
      () => provisionUseCase(student: newStudent, email: 'student@example.com'),
    ).called(1);
    await bloc.close();
  });

  test(
    'create emits loaded success contract after successful mutation',
    () async {
      final admin = actor(UserRole.admin);
      final newStudent = student(id: 'local-id');

      when(
        () => canMutateStudent.canCreate(admin, newStudent),
      ).thenReturn(true);
      when(
        () => provisionUseCase(student: newStudent),
      ).thenAnswer((_) async => 's1');

      final bloc = StudentDataBloc(
        studentRepository: repository,
        getStudentsList: getStudentsList,
        canMutateStudent: canMutateStudent,
        provisionUseCase: provisionUseCase,
      );

      final expectation = expectLater(
        bloc.stream,
        emits(
          isA<StudentDataLoaded>()
              .having(
                (s) => s.mutationStatus,
                'mutationStatus',
                StudentMutationStatus.success,
              )
              .having((s) => s.successMessage, 'successMessage', isNotEmpty),
        ),
      );

      bloc.add(StudentCreated(actor: admin, student: newStudent));
      await expectation;
      verify(() => provisionUseCase(student: newStudent)).called(1);
      await bloc.close();
    },
  );

  test('delete archives linked user and emits success message', () async {
    final adminActor = actor(UserRole.admin);
    final existing = student(id: 's3');

    when(
      () => repository.getStudentById('s3'),
    ).thenAnswer((_) async => existing);
    when(
      () => canMutateStudent.canDelete(adminActor, existing),
    ).thenReturn(true);

    when(
      () =>
          provisionUseCase.archive(docId: 's3', performedByUid: adminActor.uid),
    ).thenAnswer((_) async {});

    final bloc = StudentDataBloc(
      studentRepository: repository,
      getStudentsList: getStudentsList,
      canMutateStudent: canMutateStudent,
      provisionUseCase: provisionUseCase,
    );

    final expectation = expectLater(
      bloc.stream,
      emits(
        isA<StudentDataLoaded>().having(
          (s) => s.successMessage,
          'successMessage',
          isNotEmpty,
        ),
      ),
    );

    bloc.add(StudentDeleted(actor: adminActor, docId: 's3'));
    await expectation;
    verify(
      () =>
          provisionUseCase.archive(docId: 's3', performedByUid: adminActor.uid),
    ).called(1);
    await bloc.close();
  });

  test('restore re-enables linked account and emits success message', () async {
    final adminActor = actor(UserRole.admin);
    final archived = student(id: 's4').copyWith(isArchived: true);

    when(
      () => repository.getStudentById('s4', includeArchived: true),
    ).thenAnswer((_) async => archived);

    when(
      () =>
          provisionUseCase.restore(docId: 's4', performedByUid: adminActor.uid),
    ).thenAnswer((_) async {});

    final bloc = StudentDataBloc(
      studentRepository: repository,
      getStudentsList: getStudentsList,
      canMutateStudent: canMutateStudent,
      provisionUseCase: provisionUseCase,
    );

    final expectation = expectLater(
      bloc.stream,
      emits(
        isA<StudentDataLoaded>().having(
          (s) => s.successMessage,
          'successMessage',
          isNotEmpty,
        ),
      ),
    );

    bloc.add(StudentRestored(actor: adminActor, docId: 's4'));
    await expectation;
    verify(
      () =>
          provisionUseCase.restore(docId: 's4', performedByUid: adminActor.uid),
    ).called(1);
    await bloc.close();
  });

  test('search scopes search by groupId for servant actor', () async {
    final servant = actor(UserRole.servant);
    final results = [student(id: 's5')];

    when(
      () => repository.searchStudents(
        'search term',
        limit: any(named: 'limit'),
        groupId: 'year1',
      ),
    ).thenAnswer((_) async => results);

    final bloc = StudentDataBloc(
      studentRepository: repository,
      getStudentsList: getStudentsList,
      canMutateStudent: canMutateStudent,
      provisionUseCase: provisionUseCase,
    );

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<StudentDataLoading>().having((s) => s.isSearch, 'isSearch', true),
        isA<StudentDataLoaded>()
            .having((s) => s.students.length, 'count', 1)
            .having((s) => s.currentQuery, 'query', 'search term'),
      ]),
    );

    bloc.add(StudentsSearchRequested(actor: servant, query: 'search term'));
    await expectation;

    verify(
      () => repository.searchStudents(
        'search term',
        limit: any(named: 'limit'),
        groupId: 'year1',
      ),
    ).called(1);
    await bloc.close();
  });

  test(
    'empty-query initial search emits same state shape as a load (currentQuery == null)',
    () async {
      final admin = actor(UserRole.admin);

      when(
        () => repository.getAllStudents(
          limit: 50,
          includeArchived: any(named: 'includeArchived'),
        ),
      ).thenAnswer((_) async => [student()]);

      final bloc = StudentDataBloc(
        studentRepository: repository,
        getStudentsList: getStudentsList,
        canMutateStudent: canMutateStudent,
        provisionUseCase: provisionUseCase,
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<StudentDataLoading>(),
          isA<StudentDataLoaded>()
              .having((s) => s.currentFilterTeamId, 'team', isNull)
              .having((s) => s.currentQuery, 'currentQuery', isNull)
              .having((s) => s.students.single.docID, 'student', 's1'),
        ]),
      );

      bloc.add(StudentsSearchRequested(actor: admin, query: ''));
      await expectation;
      await bloc.close();
    },
  );
}


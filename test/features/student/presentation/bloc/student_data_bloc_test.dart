import 'dart:async';

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_stream_usecase.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStudentDataRepository extends Mock implements StudentDataRepository {}

class MockGetStudentsStreamUseCase extends Mock
    implements GetStudentsStreamUseCase {}

class MockCanMutateStudentUseCase extends Mock
    implements CanMutateStudentUseCase {}

class MockAdminUserProvisioningService extends Mock
    implements AdminUserProvisioningService {}

void main() {
  late MockStudentDataRepository repository;
  late MockGetStudentsStreamUseCase getStudentsStream;
  late MockCanMutateStudentUseCase canMutateStudent;
  late MockAdminUserProvisioningService adminUserProvisioningService;

  AuthUser actor(UserRole role) => AuthUser(
    uid: 'u1',
    email: 'user@example.com',
    name: 'User',
    role: role,
    isEmailVerified: true,
    groupId: 'year1',
  );

  StudentModel student({String id = 's1', UserRole role = UserRole.student}) {
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
    );
  }

  setUpAll(() {
    registerFallbackValue(student());
    registerFallbackValue(UserRole.student);
  });

  setUp(() {
    repository = MockStudentDataRepository();
    getStudentsStream = MockGetStudentsStreamUseCase();
    canMutateStudent = MockCanMutateStudentUseCase();
    adminUserProvisioningService = MockAdminUserProvisioningService();
  });

  test(
    'load emits loading then empty loaded when actor has no stream access',
    () async {
      final admin = actor(UserRole.admin);
      when(
        () => getStudentsStream(actor: admin, teamId: null),
      ).thenReturn(null);

      final bloc = StudentDataBloc(
        studentRepository: repository,
        getStudentsStream: getStudentsStream,
        canMutateStudent: canMutateStudent,
        adminUserProvisioningService: adminUserProvisioningService,
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

  test('refresh keeps previous students visible while loading', () async {
    final admin = actor(UserRole.admin);
    final controller = StreamController<List<StudentModel>>.broadcast();
    when(
      () => getStudentsStream(actor: admin, teamId: null),
    ).thenAnswer((_) => controller.stream);

    final bloc = StudentDataBloc(
      studentRepository: repository,
      getStudentsStream: getStudentsStream,
      canMutateStudent: canMutateStudent,
      adminUserProvisioningService: adminUserProvisioningService,
    );

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<StudentDataLoading>(),
        isA<StudentDataLoaded>().having((s) => s.students.length, 'count', 1),
        isA<StudentDataLoading>()
            .having((s) => s.previousStudents.length, 'previousStudents', 1)
            .having((s) => s.isRefresh, 'isRefresh', true),
        isA<StudentDataLoaded>().having((s) => s.students.length, 'count', 1),
      ]),
    );

    bloc.add(StudentsLoadRequested(actor: admin));
    await Future<void>.delayed(Duration.zero);
    controller.add([student(id: 's1')]);
    await Future<void>.delayed(Duration.zero);
    await bloc.refresh(admin);
    controller.add([student(id: 's2')]);

    await expectation;
    await controller.close();
    await bloc.close();
  });

  test('search with changed team reloads the student stream for the new team', () async {
    final admin = actor(UserRole.admin);
    final team1Controller = StreamController<List<StudentModel>>.broadcast();
    final team2Controller = StreamController<List<StudentModel>>.broadcast();

    when(
      () => getStudentsStream(actor: admin, teamId: 'team1'),
    ).thenAnswer((_) => team1Controller.stream);
    when(
      () => getStudentsStream(actor: admin, teamId: 'team2'),
    ).thenAnswer((_) => team2Controller.stream);

    final bloc = StudentDataBloc(
      studentRepository: repository,
      getStudentsStream: getStudentsStream,
      canMutateStudent: canMutateStudent,
      adminUserProvisioningService: adminUserProvisioningService,
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
    team1Controller.add([student(id: 's1')]);
    await Future<void>.delayed(Duration.zero);

    bloc.add(
      StudentsSearchRequested(actor: admin, query: 'Student', teamId: 'team2'),
    );
    await Future<void>.delayed(Duration.zero);
    team2Controller.add([student(id: 's2')]);

    await expectation;
    await team1Controller.close();
    await team2Controller.close();
    await bloc.close();
  });

  test('create emits not-allowed when actor cannot mutate student', () async {
    final servant = actor(UserRole.servant);
    final newStudent = student();
    when(() => canMutateStudent(servant, newStudent)).thenReturn(false);

    final bloc = StudentDataBloc(
      studentRepository: repository,
      getStudentsStream: getStudentsStream,
      canMutateStudent: canMutateStudent,
      adminUserProvisioningService: adminUserProvisioningService,
    );

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<StudentDataError>().having(
          (s) => s.message,
          'message',
          'غير مسموح.',
        ),
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
      getStudentsStream: getStudentsStream,
      canMutateStudent: canMutateStudent,
      adminUserProvisioningService: adminUserProvisioningService,
    );

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<StudentDataError>().having(
          (s) => s.message,
          'message',
          'لم يتم العثور على المخدوم.',
        ),
      ]),
    );

    bloc.add(StudentUpdated(actor: admin, student: updated));
    await expectation;
    verify(() => repository.getStudentById(any())).called(1);
    await bloc.close();
  });

  test('update denies role change when actor is not admin', () async {
    final servantActor = actor(UserRole.servant);
    final existing = student(id: 's1', role: UserRole.student);
    final updated = student(id: 's1', role: UserRole.servant);

    when(
      () => repository.getStudentById('s1'),
    ).thenAnswer((_) async => existing);
    when(() => canMutateStudent(servantActor, existing)).thenReturn(true);

    final bloc = StudentDataBloc(
      studentRepository: repository,
      getStudentsStream: getStudentsStream,
      canMutateStudent: canMutateStudent,
      adminUserProvisioningService: adminUserProvisioningService,
    );

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<StudentDataError>().having(
          (s) => s.message,
          'message',
          'غير مسموح.',
        ),
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
    final existing = student(id: 's2', role: UserRole.student);
    final updated = existing.copyWith(uid: '   ', role: UserRole.servant);

    when(
      () => repository.getStudentById('s2'),
    ).thenAnswer((_) async => existing);
    when(() => canMutateStudent(adminActor, existing)).thenReturn(true);

    final bloc = StudentDataBloc(
      studentRepository: repository,
      getStudentsStream: getStudentsStream,
      canMutateStudent: canMutateStudent,
      adminUserProvisioningService: adminUserProvisioningService,
    );

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<StudentDataError>().having(
          (s) => s.message,
          'message',
          'لا يمكن ترقية المخدوم بدون حساب مستخدم مرتبط.',
        ),
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

  test('create rolls back linked auth user when student write fails', () async {
    final admin = actor(UserRole.admin);
    final newStudent = student(id: 'local-id');
    final linkedAuthUser = AuthUser(
      uid: 'auth-uid',
      email: 'student@example.com',
      name: newStudent.name,
      role: UserRole.student,
      isEmailVerified: false,
    );

    when(() => canMutateStudent(admin, newStudent)).thenReturn(true);
    when(
      () => adminUserProvisioningService.createUser(
        email: 'student@example.com',
        password: 'secret123',
        name: newStudent.name,
        role: UserRole.student,
      ),
    ).thenAnswer((_) async => linkedAuthUser);
    when(
      () => repository.createStudent(
        newStudent.copyWith(uid: 'auth-uid', docID: 'auth-uid'),
      ),
    ).thenThrow(Exception('write failed'));
    when(
      () => adminUserProvisioningService.rollbackCreatedUser(
        uid: 'auth-uid',
        email: 'student@example.com',
        password: 'secret123',
      ),
    ).thenAnswer((_) async {});

    final bloc = StudentDataBloc(
      studentRepository: repository,
      getStudentsStream: getStudentsStream,
      canMutateStudent: canMutateStudent,
      adminUserProvisioningService: adminUserProvisioningService,
    );

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<StudentDataError>().having(
          (s) => s.message,
          'message',
          'تعذر إنشاء المخدوم. حاول مرة أخرى.',
        ),
      ]),
    );

    bloc.add(
      StudentCreated(
        actor: admin,
        student: newStudent,
        email: 'student@example.com',
        password: 'secret123',
      ),
    );

    await expectation;
    verify(() => repository.createStudent(any())).called(1);
    verify(
      () => adminUserProvisioningService.rollbackCreatedUser(
        uid: 'auth-uid',
        email: 'student@example.com',
        password: 'secret123',
      ),
    ).called(1);
    await bloc.close();
  });

  test(
    'create emits loaded success contract after successful mutation',
    () async {
      final admin = actor(UserRole.admin);
      final newStudent = student(id: 'local-id');

      when(() => canMutateStudent(admin, newStudent)).thenReturn(true);
      when(
        () => repository.createStudent(newStudent),
      ).thenAnswer((_) async => 's1');

      final bloc = StudentDataBloc(
        studentRepository: repository,
        getStudentsStream: getStudentsStream,
        canMutateStudent: canMutateStudent,
        adminUserProvisioningService: adminUserProvisioningService,
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
              .having(
                (s) => s.successMessage,
                'successMessage',
                'تم إنشاء المخدوم بنجاح',
              ),
        ),
      );

      bloc.add(StudentCreated(actor: admin, student: newStudent));
      await expectation;
      verify(() => repository.createStudent(newStudent)).called(1);
      await bloc.close();
    },
  );

  test('delete archives linked user and emits success message', () async {
    final adminActor = actor(UserRole.admin);
    final existing = student(id: 's3');

    when(() => repository.getStudentById('s3')).thenAnswer((_) async => existing);
    when(() => canMutateStudent(adminActor, existing)).thenReturn(true);
    when(() => repository.deleteStudent('s3')).thenAnswer((_) async {});
    when(
      () => adminUserProvisioningService.archiveUser(uid: 's3'),
    ).thenAnswer((_) async {});

    final bloc = StudentDataBloc(
      studentRepository: repository,
      getStudentsStream: getStudentsStream,
      canMutateStudent: canMutateStudent,
      adminUserProvisioningService: adminUserProvisioningService,
    );

    final expectation = expectLater(
      bloc.stream,
      emits(
        isA<StudentDataLoaded>().having(
          (s) => s.successMessage,
          'successMessage',
          'تمت أرشفة المخدوم بنجاح',
        ),
      ),
    );

    bloc.add(StudentDeleted(actor: adminActor, docId: 's3'));
    await expectation;
    verify(() => adminUserProvisioningService.archiveUser(uid: 's3')).called(1);
    await bloc.close();
  });

  test('restore re-enables linked account and emits success message', () async {
    final adminActor = actor(UserRole.admin);
    final archived = student(id: 's4').copyWith(isArchived: true);

    when(
      () => repository.getStudentById('s4', includeArchived: true),
    ).thenAnswer((_) async => archived);
    when(() => repository.restoreStudent('s4')).thenAnswer((_) async {});
    when(
      () => adminUserProvisioningService.restoreUser(uid: 's4'),
    ).thenAnswer((_) async {});

    final bloc = StudentDataBloc(
      studentRepository: repository,
      getStudentsStream: getStudentsStream,
      canMutateStudent: canMutateStudent,
      adminUserProvisioningService: adminUserProvisioningService,
    );

    final expectation = expectLater(
      bloc.stream,
      emits(
        isA<StudentDataLoaded>().having(
          (s) => s.successMessage,
          'successMessage',
          'تمت استعادة المخدوم بنجاح',
        ),
      ),
    );

    bloc.add(StudentRestored(actor: adminActor, docId: 's4'));
    await expectation;
    verify(() => repository.restoreStudent('s4')).called(1);
    verify(() => adminUserProvisioningService.restoreUser(uid: 's4')).called(1);
    await bloc.close();
  });
}

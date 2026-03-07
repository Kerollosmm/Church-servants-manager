import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/auth/data/services/auth_service.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_managment_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_managment_system/features/student/domain/usecases/get_students_stream_usecase.dart';
import 'package:church_managment_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStudentDataRepository extends Mock implements StudentDataRepository {}

class MockGetStudentsStreamUseCase extends Mock
    implements GetStudentsStreamUseCase {}

class MockCanMutateStudentUseCase extends Mock
    implements CanMutateStudentUseCase {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockStudentDataRepository repository;
  late MockGetStudentsStreamUseCase getStudentsStream;
  late MockCanMutateStudentUseCase canMutateStudent;
  late MockAuthService authService;

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
    authService = MockAuthService();
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
        authService: authService,
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<StudentDataLoading>(),
          isA<StudentDataLoaded>().having((s) => s.students.length, 'count', 0),
        ]),
      );

      bloc.add(StudentsLoadRequested(actor: admin));
      await expectation;
      await bloc.close();
    },
  );

  test('create emits not-allowed when actor cannot mutate student', () async {
    final servant = actor(UserRole.servant);
    final newStudent = student();
    when(() => canMutateStudent(servant, newStudent)).thenReturn(false);

    final bloc = StudentDataBloc(
      studentRepository: repository,
      getStudentsStream: getStudentsStream,
      canMutateStudent: canMutateStudent,
      authService: authService,
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
      authService: authService,
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
      authService: authService,
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
      authService: authService,
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
      () => authService.createUserAsAdmin(
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
      () => authService.rollbackAdminCreatedUser(
        uid: 'auth-uid',
        email: 'student@example.com',
        password: 'secret123',
      ),
    ).thenAnswer((_) async {});

    final bloc = StudentDataBloc(
      studentRepository: repository,
      getStudentsStream: getStudentsStream,
      canMutateStudent: canMutateStudent,
      authService: authService,
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
      () => authService.rollbackAdminCreatedUser(
        uid: 'auth-uid',
        email: 'student@example.com',
        password: 'secret123',
      ),
    ).called(1);
    await bloc.close();
  });
}

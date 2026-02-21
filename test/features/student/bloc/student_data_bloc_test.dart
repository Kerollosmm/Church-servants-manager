import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
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

void main() {
  late MockStudentDataRepository mockRepository;
  late MockGetStudentsStreamUseCase mockGetStudentsStream;
  const canMutateStudent = CanMutateStudentUseCase();
  late List<StudentModel> allStudents;
  late List<StudentModel> year1Students;

  const admin = AuthUser(
    uid: 'admin-1',
    email: 'admin@test.com',
    name: 'Admin',
    role: UserRole.admin,
    isEmailVerified: true,
  );

  const teacherYear1 = AuthUser(
    uid: 'teacher-1',
    email: 't@test.com',
    name: 'Teacher',
    role: UserRole.servant,
    groupId: 'year1',
    isEmailVerified: true,
  );

  const studentUser = AuthUser(
    uid: 'student-actor',
    email: 's@test.com',
    name: 'Student',
    role: UserRole.student,
    isEmailVerified: true,
  );

  setUpAll(() {
    registerFallbackValue(
      StudentModel(
        uid: 'fallback',
        docID: 'fallback',
        name: 'Fallback',
        imageUrl: null,
        role: UserRole.student,
        mobile: '0',
        group: Group.year1,
        teamName: 'Team',
        motherPhone: '0',
        fatherPhone: '0',
        grade: 1,
        educationStage: EducationStage.preparatory,
        school: null,
        address: null,
        birthdate: null,
        fatherOfConfession: 'Fr.',
        notes: null,
        classId: 'year1',
      ),
    );
    registerFallbackValue(admin);
  });

  setUp(() {
    mockRepository = MockStudentDataRepository();
    mockGetStudentsStream = MockGetStudentsStreamUseCase();

    allStudents = List.generate(10, (i) {
      final group = i.isEven ? Group.year1 : Group.year2;
      return StudentModel(
        uid: 'uid-$i',
        docID: 'doc-$i',
        name: 'Student $i',
        imageUrl: null,
        role: UserRole.student,
        mobile: '01234567890',
        group: group,
        teamName: 'Team A',
        motherPhone: '01111111111',
        fatherPhone: '02222222222',
        grade: 1,
        educationStage: EducationStage.preparatory,
        school: null,
        address: null,
        birthdate: null,
        fatherOfConfession: 'Fr. Test',
        notes: null,
        classId: group.name,
      );
    });

    year1Students = allStudents.where((s) => s.classId == 'year1').toList();
  });

  StudentDataBloc buildBloc() => StudentDataBloc(
    studentRepository: mockRepository,
    getStudentsStream: mockGetStudentsStream,
    canMutateStudent: canMutateStudent,
  );

  group('StudentDataBloc', () {
    blocTest<StudentDataBloc, StudentDataState>(
      'admin can load all students via stream',
      setUp: () {
        when(
          () => mockGetStudentsStream(
            actor: any(named: 'actor'),
            teamId: any(named: 'teamId'),
          ),
        ).thenAnswer((_) => Stream.value(allStudents));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const StudentsLoadRequested(actor: admin)),
      expect: () => [
        isA<StudentDataLoading>(),
        isA<StudentDataLoaded>().having((s) => s.students.length, 'count', 10),
      ],
    );

    blocTest<StudentDataBloc, StudentDataState>(
      'teacher loads only their group via stream',
      setUp: () {
        when(
          () => mockGetStudentsStream(
            actor: any(named: 'actor'),
            teamId: any(named: 'teamId'),
          ),
        ).thenAnswer((_) => Stream.value(year1Students));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const StudentsLoadRequested(actor: teacherYear1)),
      expect: () => [
        isA<StudentDataLoading>(),
        isA<StudentDataLoaded>().having(
          (s) => s.students.length,
          'count',
          year1Students.length,
        ),
      ],
    );

    blocTest<StudentDataBloc, StudentDataState>(
      'student gets empty list (null stream)',
      setUp: () {
        when(
          () => mockGetStudentsStream(
            actor: any(named: 'actor'),
            teamId: any(named: 'teamId'),
          ),
        ).thenAnswer((_) => null);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const StudentsLoadRequested(actor: studentUser)),
      expect: () => [
        isA<StudentDataLoading>(),
        isA<StudentDataLoaded>().having(
          (s) => s.students.isEmpty,
          'empty',
          true,
        ),
      ],
    );

    blocTest<StudentDataBloc, StudentDataState>(
      'teacher update blocked if student not in their class',
      setUp: () {
        when(() => mockRepository.getStudentById(any())).thenAnswer((_) async {
          return allStudents.firstWhere((s) => s.classId == 'year2');
        });
      },
      build: buildBloc,
      act: (bloc) {
        final otherClassStudent = allStudents.firstWhere(
          (s) => s.classId == 'year2',
        );
        bloc.add(
          StudentUpdated(actor: teacherYear1, student: otherClassStudent),
        );
      },
      expect: () => [
        isA<StudentDataError>().having(
          (s) => s.message,
          'message',
          'Not allowed.',
        ),
      ],
    );

    blocTest<StudentDataBloc, StudentDataState>(
      'admin create emits success',
      setUp: () {
        when(
          () => mockRepository.createStudent(any()),
        ).thenAnswer((_) async => 'new-doc');
      },
      build: buildBloc,
      act: (bloc) {
        final newStudent = StudentModel(
          uid: 'new-uid',
          docID: 'temp',
          name: 'New Student',
          imageUrl: null,
          role: UserRole.student,
          mobile: '01234567890',
          group: Group.year1,
          teamName: 'Team A',
          motherPhone: '01111111111',
          fatherPhone: '02222222222',
          grade: 1,
          educationStage: EducationStage.preparatory,
          school: null,
          address: null,
          birthdate: null,
          fatherOfConfession: 'Fr.',
          notes: null,
          classId: 'year1',
        );
        bloc.add(StudentCreated(actor: admin, student: newStudent));
      },
      expect: () => [isA<StudentDataOperationSuccess>()],
      verify: (_) {
        verify(() => mockRepository.createStudent(any())).called(1);
      },
    );

    blocTest<StudentDataBloc, StudentDataState>(
      'update uses cached student and skips repository lookup when loaded',
      setUp: () {
        when(
          () => mockGetStudentsStream(
            actor: any(named: 'actor'),
            teamId: any(named: 'teamId'),
          ),
        ).thenAnswer((_) => Stream.value(allStudents));
        when(
          () => mockRepository.updateStudent(any()),
        ).thenAnswer((_) async {});
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const StudentsLoadRequested(actor: admin));
        await Future<void>.delayed(Duration.zero);
        final student = allStudents.first;
        final updated = student.copyWith(name: '${student.name} Updated');
        bloc.add(StudentUpdated(actor: admin, student: updated));
      },
      verify: (_) {
        verifyNever(() => mockRepository.getStudentById(any()));
        verify(() => mockRepository.updateStudent(any())).called(1);
      },
    );

    blocTest<StudentDataBloc, StudentDataState>(
      'delete uses cached student and skips repository lookup when loaded',
      setUp: () {
        when(
          () => mockGetStudentsStream(
            actor: any(named: 'actor'),
            teamId: any(named: 'teamId'),
          ),
        ).thenAnswer((_) => Stream.value(allStudents));
        when(
          () => mockRepository.deleteStudent(any()),
        ).thenAnswer((_) async {});
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const StudentsLoadRequested(actor: admin));
        await Future<void>.delayed(Duration.zero);
        final student = allStudents.first;
        bloc.add(StudentDeleted(actor: admin, docId: student.docID));
      },
      verify: (_) {
        verifyNever(() => mockRepository.getStudentById(any()));
        verify(() => mockRepository.deleteStudent(any())).called(1);
      },
    );
  });
}

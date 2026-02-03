import 'package:bloc_test/bloc_test.dart';
import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/models/auth_user.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_managment_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStudentDataRepository extends Mock implements StudentDataRepository {}

void main() {
  late MockStudentDataRepository mockRepository;
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
  });

  setUp(() {
    mockRepository = MockStudentDataRepository();

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

    when(
      () => mockRepository.getAllStudents(limit: any(named: 'limit')),
    ).thenAnswer((_) async => allStudents);
    when(
      () => mockRepository.getStudentsByClass('year1'),
    ).thenAnswer((_) async => year1Students);
    when(
      () => mockRepository.searchStudents('Student 1'),
    ).thenAnswer((_) async => [allStudents[1]]);
  });

  group('StudentDataBloc', () {
    blocTest<StudentDataBloc, StudentDataState>(
      'admin can load all students',
      build: () => StudentDataBloc(studentRepository: mockRepository),
      act: (bloc) => bloc.add(const StudentsLoadRequested(actor: admin)),
      expect: () => [
        isA<StudentDataLoading>(),
        isA<StudentDataLoaded>()
            .having((s) => s.students.length, 'count', 10)
            .having((s) => s.currentFilterGroupId, 'filter', null),
      ],
      verify: (_) {
        verify(() => mockRepository.getAllStudents(limit: 50)).called(1);
      },
    );

    blocTest<StudentDataBloc, StudentDataState>(
      'teacher loads only their group students',
      build: () => StudentDataBloc(studentRepository: mockRepository),
      act: (bloc) => bloc.add(const StudentsLoadRequested(actor: teacherYear1)),
      expect: () => [
        isA<StudentDataLoading>(),
        isA<StudentDataLoaded>()
            .having((s) => s.students.length, 'count', year1Students.length)
            .having((s) => s.currentFilterGroupId, 'filter', 'year1'),
      ],
      verify: (_) {
        verify(() => mockRepository.getStudentsByClass('year1')).called(1);
      },
    );

    blocTest<StudentDataBloc, StudentDataState>(
      'student cannot load list',
      build: () => StudentDataBloc(studentRepository: mockRepository),
      act: (bloc) => bloc.add(const StudentsLoadRequested(actor: studentUser)),
      expect: () => [isA<StudentDataLoading>(), isA<StudentDataError>()],
    );

    blocTest<StudentDataBloc, StudentDataState>(
      'admin search uses repository search',
      build: () => StudentDataBloc(studentRepository: mockRepository),
      act: (bloc) => bloc.add(
        const StudentsSearchRequested(actor: admin, query: 'Student 1'),
      ),
      expect: () => [
        isA<StudentDataLoading>(),
        isA<StudentDataLoaded>()
            .having((s) => s.students.length, 'count', 1)
            .having((s) => s.currentQuery, 'query', 'Student 1'),
      ],
      verify: (_) {
        verify(() => mockRepository.searchStudents('Student 1')).called(1);
      },
    );

    blocTest<StudentDataBloc, StudentDataState>(
      'teacher update blocked if student not in their class',
      build: () {
        final otherClassStudent = allStudents.firstWhere(
          (s) => s.classId == 'year2',
        );
        when(
          () => mockRepository.getStudentById(otherClassStudent.docID),
        ).thenAnswer((_) async => otherClassStudent);
        return StudentDataBloc(studentRepository: mockRepository);
      },
      act: (bloc) async {
        final otherClassStudent = allStudents.firstWhere(
          (s) => s.classId == 'year2',
        );
        bloc.add(
          StudentUpdated(actor: teacherYear1, student: otherClassStudent),
        );
      },
      expect: () => [
        isA<StudentDataLoading>(),
        isA<StudentDataError>().having(
          (s) => s.message,
          'message',
          'Not allowed.',
        ),
      ],
    );

    blocTest<StudentDataBloc, StudentDataState>(
      'admin create emits success',
      build: () {
        when(
          () => mockRepository.createStudent(any()),
        ).thenAnswer((_) async => 'new-doc');
        return StudentDataBloc(studentRepository: mockRepository);
      },
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
      expect: () => [
        isA<StudentDataLoading>(),
        isA<StudentDataOperationSuccess>(),
      ],
      verify: (_) {
        verify(() => mockRepository.createStudent(any())).called(1);
      },
    );
  });
}

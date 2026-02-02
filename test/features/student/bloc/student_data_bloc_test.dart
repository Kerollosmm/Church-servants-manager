import 'package:bloc_test/bloc_test.dart';
import 'package:church_managment_system/core/constants/enums.dart';
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
  late List<StudentModel> year2Students;

  // Register fallback values for mocktail
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
        school: 'School',
        address: 'Address',
        birthdate: DateTime(2010),
        fatherOfConfession: 'Fr.',
        notes: null,
      ),
    );
  });

  setUp(() {
    mockRepository = MockStudentDataRepository();

    // Create test data: 20 students across 3 groups
    allStudents = List.generate(20, (i) {
      final groups = [Group.year1, Group.year2, Group.year3];
      final groupIndex = i % 3;
      return StudentModel(
        uid: 'student-uid-$i',
        docID: 'student-doc-$i',
        name: 'Student $i',
        imageUrl: null,
        role: UserRole.student,
        mobile: '01234567890',
        group: groups[groupIndex],
        teamName: 'Team ${groupIndex + 1}',
        motherPhone: '01111111111',
        fatherPhone: '01222222222',
        grade: (i % 12) + 1,
        educationStage: EducationStage.preparatory,
        school: 'Test School',
        address: 'Test Address',
        birthdate: DateTime(2010, 1, 1),
        fatherOfConfession: 'Fr. Test',
        notes: null,
        classId: 'class-year${groupIndex + 1}',
      );
    });

    year1Students = allStudents.where((s) => s.group == Group.year1).toList();
    year2Students = allStudents.where((s) => s.group == Group.year2).toList();

    // Setup mock responses
    when(
      () => mockRepository.getAllStudents(limit: any(named: 'limit')),
    ).thenAnswer((_) async => allStudents);

    when(
      () => mockRepository.getStudentsByClass('year1'),
    ).thenAnswer((_) async => year1Students);

    when(
      () => mockRepository.getStudentsByClass('year2'),
    ).thenAnswer((_) async => year2Students);
  });

  group('StudentDataBloc', () {
    blocTest<StudentDataBloc, StudentDataState>(
      'emits [Loading, Loaded] with all students when admin loads without filter',
      build: () => StudentDataBloc(studentRepository: mockRepository),
      act: (bloc) => bloc.add(const StudentsLoadRequested()),
      expect: () => [
        isA<StudentDataLoading>(),
        isA<StudentDataLoaded>()
            .having((s) => s.students.length, 'count', 20)
            .having((s) => s.currentFilterGroupId, 'filter', null),
      ],
      verify: (_) {
        verify(() => mockRepository.getAllStudents(limit: 50)).called(1);
      },
    );

    blocTest<StudentDataBloc, StudentDataState>(
      'emits [Loading, Loaded] with filtered students for servant (year1)',
      build: () => StudentDataBloc(studentRepository: mockRepository),
      act: (bloc) =>
          bloc.add(const StudentsLoadRequested(filterGroupId: 'year1')),
      expect: () => [
        isA<StudentDataLoading>(),
        isA<StudentDataLoaded>()
            .having((s) => s.students.length, 'count', 7) // 20/3 ≈ 7 for year1
            .having((s) => s.currentFilterGroupId, 'filter', 'year1'),
      ],
      verify: (_) {
        verify(() => mockRepository.getStudentsByClass('year1')).called(1);
      },
    );

    blocTest<StudentDataBloc, StudentDataState>(
      'emits [Loading, Loaded] with filtered students for servant (year2)',
      build: () => StudentDataBloc(studentRepository: mockRepository),
      act: (bloc) =>
          bloc.add(const StudentsLoadRequested(filterGroupId: 'year2')),
      expect: () => [
        isA<StudentDataLoading>(),
        isA<StudentDataLoaded>()
            .having((s) => s.students.length, 'count', 7) // 20/3 ≈ 7 for year2
            .having((s) => s.currentFilterGroupId, 'filter', 'year2'),
      ],
    );

    blocTest<StudentDataBloc, StudentDataState>(
      'emits [Loading, Error] when repository throws',
      build: () {
        when(
          () => mockRepository.getAllStudents(limit: any(named: 'limit')),
        ).thenThrow(Exception('Network error'));
        return StudentDataBloc(studentRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const StudentsLoadRequested()),
      expect: () => [
        isA<StudentDataLoading>(),
        isA<StudentDataError>().having(
          (s) => s.message,
          'message',
          contains('Failed to load'),
        ),
      ],
    );

    group('CRUD Operations', () {
      final newStudent = StudentModel(
        uid: 'new-student',
        docID: 'new-doc',
        name: 'New Student',
        imageUrl: null,
        role: UserRole.student,
        mobile: '01234567890',
        group: Group.year1,
        teamName: 'Team 1',
        motherPhone: '01111111111',
        fatherPhone: '01222222222',
        grade: 5,
        educationStage: EducationStage.preparatory,
        school: 'Test School',
        address: 'Test Address',
        birthdate: DateTime(2010, 1, 1),
        fatherOfConfession: 'Fr. Test',
        notes: null,
      );

      blocTest<StudentDataBloc, StudentDataState>(
        'emits [Loading, Success, Loading, Loaded] when creating student',
        build: () {
          when(
            () => mockRepository.createStudent(any()),
          ).thenAnswer((_) async => 'new-doc-id');
          return StudentDataBloc(studentRepository: mockRepository);
        },
        act: (bloc) => bloc.add(StudentCreated(newStudent)),
        expect: () => [
          isA<StudentDataLoading>(),
          isA<StudentDataOperationSuccess>(),
          isA<StudentDataLoading>(),
          isA<StudentDataLoaded>(),
        ],
      );

      blocTest<StudentDataBloc, StudentDataState>(
        'emits [Loading, Success, Loading, Loaded] when updating student',
        build: () {
          when(
            () => mockRepository.updateStudent(any()),
          ).thenAnswer((_) async {});
          return StudentDataBloc(studentRepository: mockRepository);
        },
        act: (bloc) => bloc.add(StudentUpdated(newStudent)),
        expect: () => [
          isA<StudentDataLoading>(),
          isA<StudentDataOperationSuccess>(),
          isA<StudentDataLoading>(),
          isA<StudentDataLoaded>(),
        ],
      );

      blocTest<StudentDataBloc, StudentDataState>(
        'emits [Loading, Success, Loading, Loaded] when deleting student',
        build: () {
          when(
            () => mockRepository.deleteStudent(any()),
          ).thenAnswer((_) async {});
          return StudentDataBloc(studentRepository: mockRepository);
        },
        act: (bloc) => bloc.add(const StudentDeleted('doc-to-delete')),
        expect: () => [
          isA<StudentDataLoading>(),
          isA<StudentDataOperationSuccess>(),
          isA<StudentDataLoading>(),
          isA<StudentDataLoaded>(),
        ],
      );
    });
  });
}

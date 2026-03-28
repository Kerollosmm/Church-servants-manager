import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_profile/student_profile_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStudentRepository extends Mock implements IStudentRepository {}

void main() {
  late MockStudentRepository repository;
  late StudentProfileCubit cubit;

  StudentModel student() => StudentModel(
    uid: 'student-user',
    docID: 'student-doc',
    name: 'Samuel',
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
    fatherOfConfession: 'Fr.',
    notes: null,
    classId: 'team-a',
  );

  setUp(() {
    repository = MockStudentRepository();
    cubit = StudentProfileCubit(studentRepository: repository);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('load emits loading then loaded when linked user profile exists', () async {
    when(
      () => repository.getStudentByLinkedUserId(
        'linked-uid',
        includeArchived: false,
      ),
    ).thenAnswer((_) async => student());
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<StudentProfileLoading>(),
        isA<StudentProfileLoaded>(),
      ]),
    );

    await cubit.load('linked-uid');
    await expectation;
    expect((cubit.state as StudentProfileLoaded).student.docID, 'student-doc');
  });

  test('load emits loading then error when linked profile is missing', () async {
    when(
      () => repository.getStudentByLinkedUserId(
        'missing-uid',
        includeArchived: false,
      ),
    ).thenAnswer((_) async => null);
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<StudentProfileLoading>(),
        isA<StudentProfileError>(),
      ]),
    );

    await cubit.load('missing-uid');
    await expectation;
    expect((cubit.state as StudentProfileError).message, 'Student profile not found.');
  });
}

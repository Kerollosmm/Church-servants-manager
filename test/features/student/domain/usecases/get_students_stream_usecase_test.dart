import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/domain/repos/i_student_repository.dart';
import 'package:church_managment_system/features/student/domain/usecases/get_students_stream_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStudentRepository extends Mock implements IStudentRepository {}

void main() {
  late MockStudentRepository repository;
  late GetStudentsStreamUseCase useCase;

  StudentModel studentWithClass(String docId, String classId) => StudentModel(
    uid: 'uid-$docId',
    docID: docId,
    name: 'Student $docId',
    imageUrl: null,
    role: UserRole.student,
    mobile: '0100000000',
    group: Group.year1,
    teamName: 'Team',
    motherPhone: '0100000000',
    fatherPhone: '0100000000',
    grade: 1,
    educationStage: EducationStage.preparatory,
    school: null,
    address: null,
    birthdate: null,
    fatherOfConfession: 'Fr.',
    notes: null,
    classId: classId,
  );

  setUp(() {
    repository = MockStudentRepository();
    useCase = GetStudentsStreamUseCase(repository);
  });

  test('admin without team filter watches all students', () async {
    const actor = AuthUser(
      uid: 'admin-1',
      email: 'admin@test.com',
      name: 'Admin',
      role: UserRole.admin,
    );
    final students = [studentWithClass('1', 'team-a')];
    when(
      () => repository.watchAllStudents(),
    ).thenAnswer((_) => Stream.value(students));

    final stream = useCase(actor: actor);
    expect(stream, isNotNull);
    await expectLater(stream!, emits(students));
    verify(() => repository.watchAllStudents()).called(1);
  });

  test('servant with one assigned team watches that team stream', () async {
    const actor = AuthUser(
      uid: 'servant-1',
      email: 'servant@test.com',
      name: 'Servant',
      role: UserRole.servant,
      groupId: 'year1',
      assignedTeamIds: ['team-a'],
    );
    final students = [studentWithClass('1', 'team-a')];
    when(
      () => repository.watchStudentsByClass('team-a'),
    ).thenAnswer((_) => Stream.value(students));

    final stream = useCase(actor: actor);
    expect(stream, isNotNull);
    await expectLater(stream!, emits(students));
    verify(() => repository.watchStudentsByClass('team-a')).called(1);
  });

  test(
    'servant with multiple assigned teams uses batched class stream',
    () async {
      const actor = AuthUser(
        uid: 'servant-2',
        email: 'servant2@test.com',
        name: 'Servant 2',
        role: UserRole.servant,
        groupId: 'year1',
        assignedTeamIds: ['team-a', 'team-b'],
      );
      final students = [
        studentWithClass('1', 'team-a'),
        studentWithClass('2', 'team-b'),
      ];
      when(
        () => repository.watchStudentsByClasses(['team-a', 'team-b']),
      ).thenAnswer((_) => Stream.value(students));

      final stream = useCase(actor: actor);
      expect(stream, isNotNull);
      await expectLater(stream!, emits(students));
      verify(
        () => repository.watchStudentsByClasses(['team-a', 'team-b']),
      ).called(1);
      verifyNever(() => repository.watchAllStudents());
    },
  );

  test('servant cannot request explicit team outside assigned scope', () {
    const actor = AuthUser(
      uid: 'servant-3',
      email: 'servant3@test.com',
      name: 'Servant 3',
      role: UserRole.servant,
      groupId: 'year1',
      assignedTeamIds: ['team-a'],
    );

    final stream = useCase(actor: actor, teamId: 'team-b');
    expect(stream, isNull);
    verifyNever(() => repository.watchStudentsByClass(any()));
    verifyNever(() => repository.watchStudentsByClasses(any()));
  });

  test('servant without assigned teams falls back to group stream', () async {
    const actor = AuthUser(
      uid: 'servant-4',
      email: 'servant4@test.com',
      name: 'Servant 4',
      role: UserRole.servant,
      groupId: 'year2',
    );
    final students = [studentWithClass('1', 'team-x')];
    when(
      () => repository.watchStudentsByGroup('year2'),
    ).thenAnswer((_) => Stream.value(students));

    final stream = useCase(actor: actor);
    expect(stream, isNotNull);
    await expectLater(stream!, emits(students));
    verify(() => repository.watchStudentsByGroup('year2')).called(1);
  });

  test('student actor has no stream access', () {
    const actor = AuthUser(
      uid: 'student-1',
      email: 'student@test.com',
      name: 'Student',
      role: UserRole.student,
    );

    final stream = useCase(actor: actor);
    expect(stream, isNull);
  });
}

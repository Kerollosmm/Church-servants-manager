import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_stream_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStudentDataRepository extends Mock implements StudentDataRepository {}

class MockGetStudentsStreamUseCase extends Mock
    implements GetStudentsStreamUseCase {}

void main() {
  late MockStudentDataRepository repository;
  late MockGetStudentsStreamUseCase streamUseCase;
  late GetStudentsUseCase useCase;

  AuthUser actor(
    UserRole role, {
    String? groupId,
    List<String> assignedTeamIds = const <String>[],
  }) => AuthUser(
    uid: 'u1',
    email: 'user@example.com',
    name: 'User',
    role: role,
    isEmailVerified: true,
    groupId: groupId,
    assignedTeamIds: assignedTeamIds,
  );

  StudentModel student({required String id, required String classId}) {
    return StudentModel(
      uid: id,
      docID: id,
      name: 'Student $id',
      imageUrl: null,
      role: UserRole.student,
      mobile: '01234567890',
      group: Group.year1,
      teamName: 'Team $classId',
      motherPhone: '01234567890',
      fatherPhone: '01234567890',
      grade: 1,
      educationStage: EducationStage.preparatory,
      school: null,
      address: null,
      birthdate: null,
      fatherOfConfession: 'Fr.',
      notes: null,
      classId: classId,
    );
  }

  setUp(() {
    repository = MockStudentDataRepository();
    streamUseCase = MockGetStudentsStreamUseCase();
    useCase = GetStudentsUseCase(repository, streamUseCase);
  });

  test('fetchPage uses class-scoped query for admin team filters', () async {
    final admin = actor(UserRole.admin);
    final teamStudents = <StudentModel>[
      student(id: 'b', classId: 'team2'),
      student(id: 'a', classId: 'team2'),
    ];

    when(
      () => repository.getStudentsByClass('team2', includeArchived: false),
    ).thenAnswer((_) async => teamStudents);

    final page = await useCase.fetchPage(actor: admin, teamId: 'team2');

    expect(page.students.map((item) => item.docID), <String>['a', 'b']);
    expect(page.hasMore, isFalse);
    verify(
      () => repository.getStudentsByClass('team2', includeArchived: false),
    ).called(1);
    verifyNever(
      () => repository.getAllStudents(
        limit: any(named: 'limit'),
        includeArchived: any(named: 'includeArchived'),
      ),
    );
  });

  test('fetchPage merges only the servant assigned teams', () async {
    final servant = actor(
      UserRole.servant,
      assignedTeamIds: const <String>['team1', 'team2'],
    );

    when(
      () => repository.getStudentsByClass('team1', includeArchived: false),
    ).thenAnswer(
      (_) async => <StudentModel>[student(id: 'a', classId: 'team1')],
    );
    when(
      () => repository.getStudentsByClass('team2', includeArchived: false),
    ).thenAnswer(
      (_) async => <StudentModel>[student(id: 'b', classId: 'team2')],
    );

    final page = await useCase.fetchPage(actor: servant, limit: 20);

    expect(page.students.map((item) => item.classId).toSet(), {
      'team1',
      'team2',
    });
    expect(page.students.map((item) => item.docID), <String>['a', 'b']);
    expect(page.hasMore, isFalse);
    verifyNever(
      () => repository.getAllStudents(
        limit: any(named: 'limit'),
        includeArchived: any(named: 'includeArchived'),
      ),
    );
  });

  test(
    'fetchPage returns empty page for unauthorized servant team filter',
    () async {
      final servant = actor(
        UserRole.servant,
        assignedTeamIds: const <String>['team1'],
      );

      final page = await useCase.fetchPage(actor: servant, teamId: 'team2');

      expect(page.students, isEmpty);
      expect(page.hasMore, isFalse);
      verifyNever(
        () => repository.getStudentsByClass(
          any(),
          includeArchived: any(named: 'includeArchived'),
        ),
      );
    },
  );
}

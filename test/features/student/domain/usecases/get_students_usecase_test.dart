import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_stream_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_usecase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStudentRepository extends Mock implements IStudentRepository {}

class MockGetStudentsStreamUseCase extends Mock
    implements GetStudentsStreamUseCase {}

void main() {
  late MockStudentRepository repository;
  late MockGetStudentsStreamUseCase streamUseCase;
  late GetStudentsUseCase useCase;
  late FakeFirebaseFirestore firestore;

  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

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

  Future<DocumentSnapshot<Map<String, dynamic>>> cursor(String id) async {
    await firestore.collection('Students').doc(id).set(<String, dynamic>{
      'name': 'Student $id',
      'isArchived': false,
    });
    return firestore.collection('Students').doc(id).get();
  }

  setUp(() {
    repository = MockStudentRepository();
    streamUseCase = MockGetStudentsStreamUseCase();
    firestore = FakeFirebaseFirestore();
    useCase = GetStudentsUseCase(repository, streamUseCase);
  });

  test(
    'fetchPage uses class-scoped page query for admin team filters',
    () async {
      final admin = actor(UserRole.admin);
      final lastDocument = await cursor('page-1');

      when(
        () => repository.getStudentsPage(
          limit: 20,
          lastDocument: null,
          classId: 'team2',
          classIds: null,
          groupName: null,
          includeArchived: false,
        ),
      ).thenAnswer(
        (_) async => StudentQueryPage(
          students: <StudentModel>[
            student(id: 'a', classId: 'team2'),
            student(id: 'b', classId: 'team2'),
          ],
          lastDocument: lastDocument,
          hasReachedMax: false,
        ),
      );

      final page = await useCase.fetchPage(actor: admin, teamId: 'team2');

      expect(page.students.map((item) => item.docID), <String>['a', 'b']);
      expect(page.lastDocument, same(lastDocument));
      expect(page.hasReachedMax, isFalse);
      verify(
        () => repository.getStudentsPage(
          limit: 20,
          lastDocument: null,
          classId: 'team2',
          classIds: null,
          groupName: null,
          includeArchived: false,
        ),
      ).called(1);
    },
  );

  test(
    'fetchPage uses assigned team ids for servant pagination scope',
    () async {
      final servant = actor(
        UserRole.servant,
        assignedTeamIds: const <String>['team1', 'team2'],
      );
      final lastDocument = await cursor('page-2');

      when(
        () => repository.getStudentsPage(
          limit: 20,
          lastDocument: null,
          classId: null,
          classIds: any(named: 'classIds'),
          groupName: null,
          includeArchived: false,
        ),
      ).thenAnswer(
        (_) async => StudentQueryPage(
          students: <StudentModel>[
            student(id: 'a', classId: 'team1'),
            student(id: 'b', classId: 'team2'),
          ],
          lastDocument: lastDocument,
          hasReachedMax: true,
        ),
      );

      final page = await useCase.fetchPage(actor: servant);

      expect(page.students.map((item) => item.classId).toSet(), <String>{
        'team1',
        'team2',
      });
      expect(page.lastDocument, same(lastDocument));
      expect(page.hasReachedMax, isTrue);
      verify(
        () => repository.getStudentsPage(
          limit: 20,
          lastDocument: null,
          classId: null,
          classIds: any(named: 'classIds'),
          groupName: null,
          includeArchived: false,
        ),
      ).called(1);
    },
  );

  test(
    'fetchPage returns empty page for unauthorized servant team filter',
    () async {
      final servant = actor(
        UserRole.servant,
        assignedTeamIds: const <String>['team1'],
      );

      final page = await useCase.fetchPage(actor: servant, teamId: 'team2');

      expect(page.students, isEmpty);
      expect(page.lastDocument, isNull);
      expect(page.hasReachedMax, isTrue);
    },
  );
}

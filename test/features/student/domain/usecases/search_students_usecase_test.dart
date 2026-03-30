import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/search_students_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStudentRepository extends Mock implements IStudentRepository {}

void main() {
  late MockStudentRepository repository;
  late SearchStudentsUseCase useCase;

  AuthUser actor(UserRole role) => AuthUser(
    uid: 'u1',
    email: 'user@example.com',
    name: 'User',
    role: role,
    isEmailVerified: true,
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
    repository = MockStudentRepository();
    useCase = SearchStudentsUseCase(repository);
  });

  test(
    'delegates search to repository with server-side query arguments',
    () async {
      when(
        () =>
            repository.searchStudents('sam', limit: 20, includeArchived: false),
      ).thenAnswer(
        (_) async => <StudentModel>[student(id: 's1', classId: 'team-1')],
      );

      final results = await useCase(
        actor: actor(UserRole.admin),
        query: 'sam',
        limit: 20,
        includeArchived: false,
      );

      expect(results, hasLength(1));
      verify(
        () =>
            repository.searchStudents('sam', limit: 20, includeArchived: false),
      ).called(1);
    },
  );
}

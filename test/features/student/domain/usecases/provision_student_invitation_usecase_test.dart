import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/student/domain/entities/student.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/provision_student_invitation_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIStudentRepository extends Mock implements IStudentRepository {}

void main() {
  late MockIStudentRepository studentRepo;
  late ProvisionStudentInvitationUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      Student(
        uid: '',
        docID: '',
        name: '',
        role: UserRole.student,
        mobile: '',
        group: Group.year1,
        teamName: '',
        motherPhone: '',
        fatherPhone: '',
        grade: 1,
        educationStage: EducationStage.preparatory,
        fatherOfConfession: '',
        classId: '',
      ),
    );
  });

  setUp(() {
    studentRepo = MockIStudentRepository();
    useCase = ProvisionStudentInvitationUseCase(studentRepository: studentRepo);
  });

  group('ProvisionStudentInvitationUseCase', () {
    test('delegates createStudent to repository', () async {
      final student = Student(
        uid: '',
        docID: '',
        name: 'Test Student',
        role: UserRole.student,
        mobile: '01234567890',
        group: Group.year1,
        teamName: 'Team A',
        motherPhone: '01234567890',
        fatherPhone: '01234567890',
        grade: 1,
        educationStage: EducationStage.preparatory,
        fatherOfConfession: 'Fr. Test',
        classId: 'team1',
      );

      when(
        () => studentRepo.createStudent(any(), email: any(named: 'email')),
      ).thenAnswer((_) async => 'doc1');

      final result = await useCase(student: student, email: 'test@example.com');

      expect(result, 'doc1');
      verify(
        () => studentRepo.createStudent(student, email: 'test@example.com'),
      ).called(1);
    });

    test('delegates archiveStudent to repository', () async {
      when(
        () => studentRepo.archiveStudent(
          any(),
          performedByUid: any(named: 'performedByUid'),
        ),
      ).thenAnswer((_) async {});

      await useCase.archive(docId: 's1', performedByUid: 'admin1');

      verify(
        () => studentRepo.archiveStudent('s1', performedByUid: 'admin1'),
      ).called(1);
    });

    test('delegates restoreStudent to repository', () async {
      when(
        () => studentRepo.restoreStudent(
          any(),
          performedByUid: any(named: 'performedByUid'),
        ),
      ).thenAnswer((_) async {});

      await useCase.restore(docId: 's1', performedByUid: 'admin1');

      verify(
        () => studentRepo.restoreStudent('s1', performedByUid: 'admin1'),
      ).called(1);
    });
  });
}

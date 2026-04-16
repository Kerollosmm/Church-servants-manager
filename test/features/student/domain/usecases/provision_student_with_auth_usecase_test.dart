import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/provision_student_with_auth_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIStudentRepository extends Mock implements IStudentRepository {}

class MockAdminUserProvisioningService extends Mock
    implements AdminUserProvisioningService {}

void main() {
  late MockIStudentRepository studentRepo;
  late MockAdminUserProvisioningService provisioningService;
  late ProvisionStudentWithAuthUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      StudentModel(
        uid: '',
        docID: '',
        name: '',
        imageUrl: null,
        role: UserRole.student,
        mobile: '',
        group: Group.year1,
        teamName: '',
        motherPhone: '',
        fatherPhone: '',
        grade: 1,
        educationStage: EducationStage.preparatory,
        school: null,
        address: null,
        birthdate: null,
        fatherOfConfession: '',
        notes: null,
        classId: '',
      ),
    );
    registerFallbackValue(UserRole.student);
  });

  setUp(() {
    studentRepo = MockIStudentRepository();
    provisioningService = MockAdminUserProvisioningService();
    useCase = ProvisionStudentWithAuthUseCase(
      studentRepository: studentRepo,
      provisioningService: provisioningService,
    );
  });

  group('ProvisionStudentWithAuthUseCase', () {
    test('creates student without auth when no credentials provided', () async {
      final student = StudentModel(
        uid: '',
        docID: '',
        name: 'Test Student',
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
        fatherOfConfession: 'Fr. Test',
        notes: null,
        classId: 'team1',
      );

      when(() => studentRepo.createStudent(any())).thenAnswer((_) async => 'doc1');

      final result = await useCase(student: student);

      expect(result, 'doc1');
      verify(() => studentRepo.createStudent(any())).called(1);
      verifyNever(() => provisioningService.createUser(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
            role: any(named: 'role'),
          ));
    });

    test('creates student with auth when credentials provided', () async {
      final student = StudentModel(
        uid: '',
        docID: '',
        name: 'Test Student',
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
        fatherOfConfession: 'Fr. Test',
        notes: null,
        classId: 'team1',
      );

      final authUser = AuthUser(
        uid: 'auth-uid',
        email: 'test@example.com',
        name: 'Test Student',
        role: UserRole.student,
      );

      when(() => provisioningService.createUser(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
            role: any(named: 'role'),
          )).thenAnswer((_) async => authUser);

      when(() => studentRepo.createStudent(any())).thenAnswer((_) async => 'doc1');

      final result = await useCase(
        student: student,
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, 'doc1');
      verify(() => provisioningService.createUser(
            email: 'test@example.com',
            password: 'password123',
            name: 'Test Student',
            role: UserRole.student,
          )).called(1);
      
      final captured = verify(() => studentRepo.createStudent(captureAny())).captured.single as StudentModel;
      expect(captured.uid, 'auth-uid');
    });

    test('rolls back auth user if Firestore creation fails', () async {
      final student = StudentModel(
        uid: '',
        docID: '',
        name: 'Test Student',
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
        fatherOfConfession: 'Fr. Test',
        notes: null,
        classId: 'team1',
      );

      final authUser = AuthUser(
        uid: 'auth-uid',
        email: 'test@example.com',
        name: 'Test Student',
        role: UserRole.student,
      );

      when(() => provisioningService.createUser(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
            role: any(named: 'role'),
          )).thenAnswer((_) async => authUser);

      when(() => studentRepo.createStudent(any()))
          .thenThrow(Exception('Firestore failed'));

      when(() => provisioningService.rollbackCreatedUser(
            uid: any(named: 'uid'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async {});

      await expectLater(
        () => useCase(
          student: student,
          email: 'test@example.com',
          password: 'password123',
        ),
        throwsA(isA<Exception>()),
      );

      verify(() => provisioningService.rollbackCreatedUser(
            uid: 'auth-uid',
            email: 'test@example.com',
            password: 'password123',
          )).called(1);
    });

    test('archive calls provisioningService.archiveUser and repo.archiveStudent', () async {
      when(() => provisioningService.archiveUser(uid: any(named: 'uid'))).thenAnswer((_) async {});
      when(() => studentRepo.archiveStudent(any(), performedByUid: any(named: 'performedByUid'))).thenAnswer((_) async {});

      await useCase.archive(docId: 's1', performedByUid: 'admin1', linkedUid: 'u1');

      verify(() => provisioningService.archiveUser(uid: 'u1')).called(1);
      verify(() => studentRepo.archiveStudent('s1', performedByUid: 'admin1')).called(1);
    });

    test('restore calls provisioningService.restoreUser and repo.restoreStudent', () async {
      when(() => provisioningService.restoreUser(uid: any(named: 'uid'))).thenAnswer((_) async {});
      when(() => studentRepo.restoreStudent(any(), performedByUid: any(named: 'performedByUid'))).thenAnswer((_) async {});

      await useCase.restore(docId: 's1', performedByUid: 'admin1', linkedUid: 'u1');

      verify(() => provisioningService.restoreUser(uid: 'u1')).called(1);
      verify(() => studentRepo.restoreStudent('s1', performedByUid: 'admin1')).called(1);
    });
  });
}

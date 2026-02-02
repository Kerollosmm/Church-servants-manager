import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/models/auth_user.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_managment_system/features/student/data/services/role_based_student_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockStudentDataRepository extends Mock implements StudentDataRepository {}

void main() {
  late MockStudentDataRepository mockStudentDataService;
  late RoleBasedStudentService roleBasedService;

  // Test data: 5 servants, 10 students per servant (50 total), 1 admin
  late AuthUser adminUser;
  late List<AuthUser> servants;
  late List<StudentModel> allStudents;

  setUp(() {
    mockStudentDataService = MockStudentDataRepository();
    roleBasedService = RoleBasedStudentService(
      studentDataService: mockStudentDataService,
    );

    // Create admin user
    adminUser = const AuthUser(
      uid: 'admin-001',
      email: 'admin@church.com',
      name: 'Admin User',
      role: UserRole.admin,
      isEmailVerified: true,
    );

    // Create 5 servants (each assigned to a different group)
    final groups = [Group.year1, Group.year2, Group.year3];
    servants = List.generate(5, (i) {
      return AuthUser(
        uid: 'servant-${i + 1}',
        email: 'servant${i + 1}@church.com',
        name: 'Servant ${i + 1}',
        role: UserRole.servant,
        isEmailVerified: true,
      );
    });

    // Create 50 students (10 per group iteration, cycling through 3 groups)
    // year1: 0-9, year2: 10-19, year3: 20-29, year1: 30-39, year2: 40-49
    allStudents = List.generate(50, (i) {
      final groupIndex = (i ~/ 10) % groups.length;
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
        classId: 'class-$groupIndex',
      );
    });

    // Setup mock to return all students
    when(
      () => mockStudentDataService.getAllStudents(limit: any(named: 'limit')),
    ).thenAnswer((_) async => allStudents);
  });

  group('Admin Access Tests', () {
    test('Admin can see all 50 students', () async {
      final result = await roleBasedService.getAccessibleStudents(
        user: adminUser,
        servantGroup: null,
      );

      expect(result.length, equals(50));
      verify(() => mockStudentDataService.getAllStudents(limit: 100)).called(1);
    });

    test('Admin can access any individual student', () {
      for (final student in allStudents) {
        expect(
          roleBasedService.canAccessStudent(
            user: adminUser,
            servantGroup: null,
            student: student,
          ),
          isTrue,
        );
      }
    });
  });

  group('Servant Access Tests', () {
    test('Servant with Group.year1 sees only year1 students', () async {
      final result = await roleBasedService.getAccessibleStudents(
        user: servants[0],
        servantGroup: Group.year1,
      );

      // year1: indices 0-9 and 30-39 = 20 students
      expect(result.length, equals(20));
      expect(result.every((s) => s.group == Group.year1), isTrue);
    });

    test('Servant with Group.year2 sees only year2 students', () async {
      final result = await roleBasedService.getAccessibleStudents(
        user: servants[1],
        servantGroup: Group.year2,
      );

      // year2: indices 10-19 and 40-49 = 20 students
      expect(result.length, equals(20));
      expect(result.every((s) => s.group == Group.year2), isTrue);
    });

    test('Servant with Group.year3 sees only year3 students', () async {
      final result = await roleBasedService.getAccessibleStudents(
        user: servants[2],
        servantGroup: Group.year3,
      );

      // year3: indices 20-29 = 10 students
      expect(result.length, equals(10));
      expect(result.every((s) => s.group == Group.year3), isTrue);
    });

    test('Servant cannot access student from different group', () {
      final year1Student = allStudents[0]; // year1 student

      expect(
        roleBasedService.canAccessStudent(
          user: servants[1],
          servantGroup: Group.year2,
          student: year1Student,
        ),
        isFalse,
      );
    });

    test('Servant can access student from their own group', () {
      final year1Student = allStudents[0]; // year1 student

      expect(
        roleBasedService.canAccessStudent(
          user: servants[0],
          servantGroup: Group.year1,
          student: year1Student,
        ),
        isTrue,
      );
    });

    test('Servant without assigned group sees no students', () async {
      final result = await roleBasedService.getAccessibleStudents(
        user: servants[0],
        servantGroup: null,
      );

      expect(result.length, equals(0));
    });
  });

  group('Student Role Tests', () {
    test('Student role user sees no students', () async {
      final studentUser = const AuthUser(
        uid: 'student-user-001',
        email: 'student@church.com',
        name: 'Student User',
        role: UserRole.student,
        isEmailVerified: true,
      );

      final result = await roleBasedService.getAccessibleStudents(
        user: studentUser,
        servantGroup: null,
      );

      expect(result.length, equals(0));
    });
  });

  group('Data Isolation Tests', () {
    test('Each servant sees exactly 10 students', () async {
      final groups = [Group.year1, Group.year2, Group.year3];

      for (var i = 0; i < 3; i++) {
        final result = await roleBasedService.getAccessibleStudents(
          user: servants[i],
          servantGroup: groups[i],
        );

        final expectedCount = groups[i] == Group.year3 ? 10 : 20;
        expect(
          result.length,
          equals(expectedCount),
          reason: 'Servant $i should see exactly $expectedCount students',
        );
      }
    });

    test('Combined servant access equals total students in groups', () async {
      final groups = [Group.year1, Group.year2, Group.year3];
      var totalFromServants = 0;

      for (var i = 0; i < 3; i++) {
        final result = await roleBasedService.getAccessibleStudents(
          user: servants[i],
          servantGroup: groups[i],
        );
        totalFromServants += result.length;
      }

      // year1: 20, year2: 20, year3: 10 = 50 total
      expect(totalFromServants, equals(50));
    });
  });
}

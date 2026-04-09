import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_session_repository.dart';
import 'package:church_management_system/features/attendance/data/services/attendance_session_service.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/services/student_query_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSessionRepository extends Mock
    implements AttendanceSessionRepository {}

class MockStudentQueryService extends Mock implements StudentQueryService {}

void main() {
  late MockSessionRepository sessionRepository;
  late MockStudentQueryService studentQueryService;
  late AttendanceSessionService service;

  final admin = const AuthUser(
    uid: 'admin-1',
    email: 'admin@example.com',
    name: 'Admin',
    role: UserRole.admin,
    isEmailVerified: true,
  );

  final student = StudentModel(
    uid: 'student-1',
    docID: 'student-1',
    name: 'Test Student',
    imageUrl: null,
    role: UserRole.student,
    group: Group.year1,
    classId: 'team-1',
    teamName: 'Team A',
    mobile: '1234567890',
    motherPhone: '0987654321',
    fatherPhone: '1122334455',
    grade: 1,
    educationStage: EducationStage.preparatory,
    school: 'Test School',
    address: 'Test Address',
    birthdate: DateTime(2010),
    fatherOfConfession: 'Father Test',
    notes: null,
  );

  setUp(() {
    sessionRepository = MockSessionRepository();
    studentQueryService = MockStudentQueryService();
    service = AttendanceSessionService(
      sessionRepository: sessionRepository,
      studentQueryService: studentQueryService,
    );
  });

  group('Session Reopen Logic', () {
    test('admin can reopen a closed session successfully', () async {
      when(
        () => sessionRepository.reopenSession(
          teamId: 'team-1',
          sessionId: 'session-1',
          reopenedByUserId: admin.uid,
          reopenedByName: admin.name,
        ),
      ).thenAnswer((_) async {});

      await service.reopenSession(
        teamId: 'team-1',
        sessionId: 'session-1',
        reopenedByUserId: admin.uid,
        reopenedByName: admin.name,
      );

      verify(
        () => sessionRepository.reopenSession(
          teamId: 'team-1',
          sessionId: 'session-1',
          reopenedByUserId: admin.uid,
          reopenedByName: admin.name,
        ),
      ).called(1);
    });

    test('reopenSession records metadata correctly', () async {
      when(
        () => sessionRepository.reopenSession(
          teamId: 'team-1',
          sessionId: 'session-1',
          reopenedByUserId: admin.uid,
          reopenedByName: admin.name,
        ),
      ).thenAnswer((_) async {});

      await service.reopenSession(
        teamId: 'team-1',
        sessionId: 'session-1',
        reopenedByUserId: admin.uid,
        reopenedByName: admin.name,
      );

      verify(
        () => sessionRepository.reopenSession(
          teamId: 'team-1',
          sessionId: 'session-1',
          reopenedByUserId: admin.uid,
          reopenedByName: admin.name,
        ),
      ).called(1);
    });

    test(
      'session creation with empty roster throws validation error',
      () async {
        when(
          () => studentQueryService.getStudentsByClass('team-1'),
        ).thenAnswer((_) async => []);

        expect(
          () => service.createSessionWithRosterSnapshot(
            teamId: 'team-1',
            teamNameSnapshot: 'Team A',
            startsAt: DateTime(2026, 3, 9, 18),
            durationMinutes: 30,
            createdBy: admin,
            title: 'Wednesday',
          ),
          throwsA(isA<AttendanceValidationFailure>()),
        );
      },
    );

    test('session creation with active students succeeds', () async {
      when(
        () => studentQueryService.getStudentsByClass('team-1'),
      ).thenAnswer((_) async => [student]);

      when(
        () => sessionRepository.createSession(
          teamId: 'team-1',
          teamNameSnapshot: 'Team A',
          startsAt: DateTime(2026, 3, 9, 18),
          durationMinutes: 30,
          createdBy: admin,
          title: 'Wednesday',
          studentIdsSnapshot: ['student-1'],
          studentNameSnapshots: {'student-1': 'Test Student'},
        ),
      ).thenAnswer((_) async {
        return AttendanceSession(
          id: '2026-03-09_1234567890_wednesday',
          teamId: 'team-1',
          teamNameSnapshot: 'Team A',
          title: 'Wednesday',
          dateKey: '2026-03-09',
          startsAt: DateTime(2026, 3, 9, 18),
          endsAt: DateTime(2026, 3, 9, 18, 30),
          durationMinutes: 30,
          createdByUserId: admin.uid,
          createdByName: admin.name,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          studentIdsSnapshot: ['student-1'],
          studentNameSnapshots: {'student-1': 'Test Student'},
        );
      });

      final session = await service.createSessionWithRosterSnapshot(
        teamId: 'team-1',
        teamNameSnapshot: 'Team A',
        startsAt: DateTime(2026, 3, 9, 18),
        durationMinutes: 30,
        createdBy: admin,
        title: 'Wednesday',
      );

      expect(session.studentIdsSnapshot, contains('student-1'));
      expect(session.title, 'Wednesday');
    });

    test('session creation filters archived students from roster', () async {
      final archivedStudent = student.copyWith(
        isArchived: true,
        docID: 'student-2',
      );

      when(
        () => studentQueryService.getStudentsByClass('team-1'),
      ).thenAnswer((_) async => [student, archivedStudent]);

      when(
        () => sessionRepository.createSession(
          teamId: 'team-1',
          teamNameSnapshot: 'Team A',
          startsAt: DateTime(2026, 3, 9, 18),
          durationMinutes: 30,
          createdBy: admin,
          title: 'Wednesday',
          studentIdsSnapshot: ['student-1'],
          studentNameSnapshots: {'student-1': 'Test Student'},
        ),
      ).thenAnswer((_) async {
        return AttendanceSession(
          id: '2026-03-09_1234567890_wednesday',
          teamId: 'team-1',
          teamNameSnapshot: 'Team A',
          title: 'Wednesday',
          dateKey: '2026-03-09',
          startsAt: DateTime(2026, 3, 9, 18),
          endsAt: DateTime(2026, 3, 9, 18, 30),
          durationMinutes: 30,
          createdByUserId: admin.uid,
          createdByName: admin.name,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          studentIdsSnapshot: ['student-1'],
          studentNameSnapshots: {'student-1': 'Test Student'},
        );
      });

      final session = await service.createSessionWithRosterSnapshot(
        teamId: 'team-1',
        teamNameSnapshot: 'Team A',
        startsAt: DateTime(2026, 3, 9, 18),
        durationMinutes: 30,
        createdBy: admin,
        title: 'Wednesday',
      );

      // Archived student should not be in the roster
      expect(session.studentIdsSnapshot, isNot(contains('student-2')));
      expect(session.studentIdsSnapshot, contains('student-1'));
    });
  });
}

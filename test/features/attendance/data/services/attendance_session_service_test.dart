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

  setUpAll(() {
    registerFallbackValue(admin);
  });

  StudentModel student({
    required String id,
    required String name,
    bool isArchived = false,
  }) {
    return StudentModel(
      uid: id,
      docID: id,
      name: name,
      imageUrl: null,
      role: UserRole.student,
      mobile: '01234567890',
      group: Group.year1,
      teamName: 'Team A',
      motherPhone: '',
      fatherPhone: '',
      grade: 1,
      educationStage: EducationStage.preparatory,
      school: null,
      address: null,
      birthdate: null,
      fatherOfConfession: '',
      notes: null,
      classId: 'team-1',
      isArchived: isArchived,
    );
  }

  AttendanceSession buildSession({
    required DateTime startsAt,
    required DateTime endsAt,
    List<String> studentIds = const ['student-1'],
  }) {
    return AttendanceSession(
      id: '2026-03-09_${startsAt.toUtc().millisecondsSinceEpoch}_session',
      teamId: 'team-1',
      teamNameSnapshot: 'Team A',
      title: 'Wednesday',
      dateKey: AttendanceSession.buildDateKey(startsAt),
      startsAt: startsAt,
      endsAt: endsAt,
      durationMinutes: 30,
      createdByUserId: admin.uid,
      createdByName: admin.name,
      createdAt: startsAt,
      updatedAt: startsAt,
      studentIdsSnapshot: studentIds,
      studentNameSnapshots: {for (final id in studentIds) id: 'Student'},
    );
  }

  setUp(() {
    sessionRepository = MockSessionRepository();
    studentQueryService = MockStudentQueryService();
    service = AttendanceSessionService(
      sessionRepository: sessionRepository,
      studentQueryService: studentQueryService,
    );
  });

  group('createSessionWithRosterSnapshot', () {
    test('creates session with active students', () async {
      final startsAt = DateTime(2026, 3, 9, 18, 0);
      final endsAt = startsAt.add(const Duration(minutes: 30));

      when(
        () => studentQueryService.getStudentsByClass('team-1'),
      ).thenAnswer((_) async => [student(id: 'student-1', name: 'Mina')]);

      final session = buildSession(startsAt: startsAt, endsAt: endsAt);
      when(
        () => sessionRepository.createSession(
          teamId: 'team-1',
          teamNameSnapshot: 'Team A',
          startsAt: startsAt,
          durationMinutes: 30,
          createdBy: admin,
          title: 'Wednesday',
          studentIdsSnapshot: ['student-1'],
          studentNameSnapshots: {'student-1': 'Mina'},
        ),
      ).thenAnswer((_) async => session);

      final result = await service.createSessionWithRosterSnapshot(
        teamId: 'team-1',
        teamNameSnapshot: 'Team A',
        startsAt: startsAt,
        durationMinutes: 30,
        createdBy: admin,
        title: 'Wednesday',
      );

      expect(result.id, session.id);
      verify(
        () => sessionRepository.createSession(
          teamId: 'team-1',
          teamNameSnapshot: 'Team A',
          startsAt: startsAt,
          durationMinutes: 30,
          createdBy: admin,
          title: 'Wednesday',
          studentIdsSnapshot: ['student-1'],
          studentNameSnapshots: {'student-1': 'Mina'},
        ),
      ).called(1);
    });

    test('throws error for empty roster (EC-01)', () async {
      when(
        () => studentQueryService.getStudentsByClass('team-1'),
      ).thenAnswer((_) async => []);

      expect(
        () => service.createSessionWithRosterSnapshot(
          teamId: 'team-1',
          teamNameSnapshot: 'Team A',
          startsAt: DateTime(2026, 3, 9, 18, 0),
          durationMinutes: 30,
          createdBy: admin,
          title: 'Wednesday',
        ),
        throwsA(isA<AttendanceValidationFailure>()),
      );

      verifyNever(
        () => sessionRepository.createSession(
          teamId: any(named: 'teamId'),
          teamNameSnapshot: any(named: 'teamNameSnapshot'),
          startsAt: any(named: 'startsAt'),
          durationMinutes: any(named: 'durationMinutes'),
          createdBy: any(named: 'createdBy'),
          title: any(named: 'title'),
          studentIdsSnapshot: any(named: 'studentIdsSnapshot'),
          studentNameSnapshots: any(named: 'studentNameSnapshots'),
        ),
      );
    });

    test('filters archived students from roster', () async {
      when(() => studentQueryService.getStudentsByClass('team-1')).thenAnswer(
        (_) async => [
          student(id: 'student-1', name: 'Mina', isArchived: false),
          student(id: 'student-2', name: 'Andrew', isArchived: true),
        ],
      );

      final session = buildSession(
        startsAt: DateTime(2026, 3, 9, 18, 0),
        endsAt: DateTime(2026, 3, 9, 18, 30),
        studentIds: ['student-1'],
      );

      when(
        () => sessionRepository.createSession(
          teamId: 'team-1',
          teamNameSnapshot: 'Team A',
          startsAt: DateTime(2026, 3, 9, 18, 0),
          durationMinutes: 30,
          createdBy: admin,
          title: 'Wednesday',
          studentIdsSnapshot: ['student-1'],
          studentNameSnapshots: {'student-1': 'Mina'},
        ),
      ).thenAnswer((_) async => session);

      await service.createSessionWithRosterSnapshot(
        teamId: 'team-1',
        teamNameSnapshot: 'Team A',
        startsAt: DateTime(2026, 3, 9, 18, 0),
        durationMinutes: 30,
        createdBy: admin,
        title: 'Wednesday',
      );

      verify(
        () => sessionRepository.createSession(
          teamId: 'team-1',
          teamNameSnapshot: 'Team A',
          startsAt: DateTime(2026, 3, 9, 18, 0),
          durationMinutes: 30,
          createdBy: admin,
          title: 'Wednesday',
          studentIdsSnapshot: ['student-1'],
          studentNameSnapshots: {'student-1': 'Mina'},
        ),
      ).called(1);
    });

    test('sorts students alphabetically by name', () async {
      when(() => studentQueryService.getStudentsByClass('team-1')).thenAnswer(
        (_) async => [
          student(id: 's3', name: 'Zach'),
          student(id: 's1', name: 'Andrew'),
          student(id: 's2', name: 'Mina'),
        ],
      );

      final session = buildSession(
        startsAt: DateTime(2026, 3, 9, 18, 0),
        endsAt: DateTime(2026, 3, 9, 18, 30),
        studentIds: ['s1', 's2', 's3'],
      );

      when(
        () => sessionRepository.createSession(
          teamId: 'team-1',
          teamNameSnapshot: 'Team A',
          startsAt: DateTime(2026, 3, 9, 18, 0),
          durationMinutes: 30,
          createdBy: admin,
          title: 'Wednesday',
          studentIdsSnapshot: ['s1', 's2', 's3'],
          studentNameSnapshots: {'s1': 'Andrew', 's2': 'Mina', 's3': 'Zach'},
        ),
      ).thenAnswer((_) async => session);

      await service.createSessionWithRosterSnapshot(
        teamId: 'team-1',
        teamNameSnapshot: 'Team A',
        startsAt: DateTime(2026, 3, 9, 18, 0),
        durationMinutes: 30,
        createdBy: admin,
        title: 'Wednesday',
      );

      verify(
        () => sessionRepository.createSession(
          teamId: 'team-1',
          teamNameSnapshot: 'Team A',
          startsAt: DateTime(2026, 3, 9, 18, 0),
          durationMinutes: 30,
          createdBy: admin,
          title: 'Wednesday',
          studentIdsSnapshot: ['s1', 's2', 's3'],
          studentNameSnapshots: {'s1': 'Andrew', 's2': 'Mina', 's3': 'Zach'},
        ),
      ).called(1);
    });
  });
}

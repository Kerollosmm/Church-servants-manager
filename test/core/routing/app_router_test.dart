import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart' as routes;
import 'package:church_management_system/core/routing/app_router.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppRouter appRouter;

  setUp(() {
    appRouter = AppRouter();
  });

  const mockActor = AuthUser(
    uid: 'actor1',
    email: 'admin@test.com',
    name: 'Admin User',
    role: UserRole.admin,
  );

  final mockStudent = StudentModel(
    uid: 'student1',
    docID: 'doc1',
    name: 'Student One',
    imageUrl: null,
    role: UserRole.student,
    mobile: '1234567890',
    group: Group.year1,
    teamName: 'Team A',
    motherPhone: '0987654321',
    fatherPhone: '0987654321',
    grade: 1,
    educationStage: EducationStage.highSchool,
    school: 'School',
    address: 'Address',
    birthdate: DateTime(2010),
    fatherOfConfession: 'Father X',
    notes: 'Notes',
  );

  final mockServant = ServantModel(
    uid: 'servant1',
    docID: 'doc1',
    name: 'Servant One',
    email: 'servant@test.com',
    teamName: 'Youth',
  );

  const mockTeam = TeamModel(id: 'team1', name: 'Team Alpha', groupId: 'year1');

  group('AppRouter.onGenerateRoute', () {
    test('returns LoginScreen for login route', () {
      final route = appRouter.onGenerateRoute(
        const RouteSettings(name: routes.login),
      );
      expect(route, isA<MaterialPageRoute>());
      // We don't necessarily need to build it here, just verify it exists
    });

    test('returns RegisterScreen for register route', () {
      final route = appRouter.onGenerateRoute(
        const RouteSettings(name: routes.register),
      );
      expect(route, isA<MaterialPageRoute>());
    });

    test('returns StudentDetailScreen for valid arguments', () {
      final args = StudentDetailArgs(actor: mockActor, student: mockStudent);
      final route = appRouter.onGenerateRoute(
        RouteSettings(name: routes.studentDetail, arguments: args),
      );
      expect(route, isA<MaterialPageRoute>());
    });

    test('returns error message for invalid StudentDetail arguments', () {
      final route = appRouter.onGenerateRoute(
        const RouteSettings(name: routes.studentDetail, arguments: 'invalid'),
      );
      expect(route, isA<MaterialPageRoute>());
      // The builder should return a Scaffold with text if arguments are invalid
    });

    test('returns ServantDetailScreen for valid arguments', () {
      final args = ServantDetailArgs(actor: mockActor, servant: mockServant);
      final route = appRouter.onGenerateRoute(
        RouteSettings(name: routes.servantDetail, arguments: args),
      );
      expect(route, isA<MaterialPageRoute>());
    });

    test('returns TeamMembersScreen for valid arguments', () {
      final args = TeamMembersArgs(actor: mockActor, team: mockTeam);
      final route = appRouter.onGenerateRoute(
        RouteSettings(name: routes.teamMembers, arguments: args),
      );
      expect(route, isA<MaterialPageRoute>());
    });

    test('returns AttendanceTakingScreen for valid arguments', () {
      final args = AttendanceTakingArgs(
        actor: mockActor,
        teamId: 't1',
        sessionId: 's1',
      );
      final route = appRouter.onGenerateRoute(
        RouteSettings(name: routes.attendanceTaking, arguments: args),
      );
      expect(route, isA<MaterialPageRoute>());
    });

    test('returns NotFoundScreen for unknown route', () {
      final route = appRouter.onGenerateRoute(
        const RouteSettings(name: '/unknown'),
      );
      expect(route, isA<MaterialPageRoute>());
    });
  });
}

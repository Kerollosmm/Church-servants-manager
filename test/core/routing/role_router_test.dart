// T007 [US2]: Unit test for RoleRouter.resolve covering all AuthState sealed types.
// Verifies that type-safe pattern matching handles AuthAuthenticated, AuthDegraded,
// and unexpected states without crashing (SC-001).

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/core/routing/role_router.dart';
import 'package:church_management_system/features/servant/presentation/screens/servant_dashboard_screen.dart';
import 'package:church_management_system/features/student/presentation/screens/student_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

// Helper auth users
// FIX [P1-B]: AuthAuthenticated uses positional arg; AuthDegraded uses named args.
const _adminUser = AuthUser(
  uid: 'admin-1',
  email: 'admin@test.com',
  name: 'Admin',
  role: UserRole.admin,
  isEmailVerified: true,
  assignedTeamIds: [],
  assignedTeamId: null,
);

const _servantUser = AuthUser(
  uid: 'servant-1',
  email: 'servant@test.com',
  name: 'Servant',
  role: UserRole.servant,
  isEmailVerified: true,
  assignedTeamIds: ['team-1'],
  assignedTeamId: 'team-1',
);

const _studentUser = AuthUser(
  uid: 'student-1',
  email: 'student@test.com',
  name: 'Student',
  role: UserRole.student,
  isEmailVerified: true,
  assignedTeamIds: [],
  assignedTeamId: null,
);

void main() {
  // T007 [US2]: These are pure unit tests of RoleRouter.resolve return types.
  // We test the widget type returned — not the full widget tree — because
  // AdminDashboardScreen and other screens depend on additional providers
  // that are out of scope for this routing unit test. // FIX [P1-B]
  group('RoleRouter.resolve — P1-B: Type-safe role-based routing', () {
    test('admin + AuthAuthenticated resolves to AdminDashboardScreen type', () {
      final state = AuthAuthenticated(_adminUser); // FIX [P1-B]: positional arg
      final widget = RoleRouter.resolve(UserRole.admin, state);
      // FIX [P1-B]: Pattern match on AuthAuthenticated() must return correct widget without unsafe cast
      expect(widget, isA<AdminDashboardScreen>());
    });

    test(
      'admin + AuthDegraded resolves to AdminRefreshRequiredScreen — no unsafe cast',
      () {
        const state = AuthDegraded(
          user: _adminUser,
          message: 'انتهت الجلسة. يرجى تسجيل الدخول مرة أخرى.',
        );
        final widget = RoleRouter.resolve(UserRole.admin, state);
        // FIX [P1-B]: Destructured message via pattern match, never via (state as AuthDegraded)
        expect(widget, isA<AdminRefreshRequiredScreen>());
        expect(
          (widget as AdminRefreshRequiredScreen).message,
          'انتهت الجلسة. يرجى تسجيل الدخول مرة أخرى.',
        );
      },
    );

    test(
      'admin + AuthLoading (no user) resolves to SizedBox.shrink — no crash',
      () {
        // AuthLoading has no user, so user == null and the method returns early. // FIX [P1-B]
        const state = AuthLoading();
        final widget = RoleRouter.resolve(UserRole.admin, state);
        // FIX [P1-B]: user==null guard returns SizedBox.shrink() before entering role switch
        expect(widget, isA<SizedBox>());
        expect(widget is AdminDashboardScreen, isFalse);
        expect(widget is AdminRefreshRequiredScreen, isFalse);
      },
    );

    test(
      'admin + AuthDegraded switch fallback never reached for valid sealed types',
      () {
        // FIX [P1-B]: Verify the nested switch _ fallback works for admin if a new
        // AuthState subclass with a user field were somehow introduced.
        // Here we test AuthAuthenticated (already handled) to confirm no crash.
        final stateAuth = AuthAuthenticated(_adminUser);
        final stateDegrad = const AuthDegraded(
          user: _adminUser,
          message: 'msg',
        );
        expect(
          RoleRouter.resolve(UserRole.admin, stateAuth),
          isA<AdminDashboardScreen>(),
        );
        expect(
          RoleRouter.resolve(UserRole.admin, stateDegrad),
          isA<AdminRefreshRequiredScreen>(),
        );
      },
    );

    test(
      'servant + AuthAuthenticated resolves to ServantDashboardScreen type',
      () {
        final state = AuthAuthenticated(
          _servantUser,
        ); // FIX [P1-B]: positional arg
        final widget = RoleRouter.resolve(UserRole.servant, state);
        expect(widget, isA<ServantDashboardScreen>());
      },
    );

    test(
      'student + AuthAuthenticated resolves to StudentProfileScreen type',
      () {
        final state = AuthAuthenticated(
          _studentUser,
        ); // FIX [P1-B]: positional arg
        final widget = RoleRouter.resolve(UserRole.student, state);
        expect(widget, isA<StudentProfileScreen>());
      },
    );

    test(
      'resolve returns SizedBox.shrink when user is null (neither Authenticated nor Degraded)',
      () {
        // user == null branch: state is neither AuthAuthenticated nor AuthDegraded
        const state = AuthUnauthenticated();
        final widget = RoleRouter.resolve(UserRole.admin, state);
        expect(widget, isA<SizedBox>());
      },
    );
  });
}

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/admin/domain/admin_policy.dart';
import 'package:church_management_system/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = AdminPolicy();

  final adminUser = AuthUser(
    uid: 'admin-1',
    email: 'admin@church.org',
    name: 'System Admin',
    role: UserRole.admin,
    isEmailVerified: true,
  );

  final servantUser = AuthUser(
    uid: 'servant-1',
    email: 'servant@church.org',
    name: 'Church Servant',
    role: UserRole.servant,
    isEmailVerified: true,
  );

  final studentUser = AuthUser(
    uid: 'student-1',
    email: 'student@church.org',
    name: 'Student User',
    role: UserRole.student,
    isEmailVerified: true,
  );

  final guestUser = AuthUser(
    uid: 'viewer-1',
    email: 'viewer@church.org',
    name: 'Viewer Guest',
    role: UserRole.student,
  );

  group('AdminPolicy unit tests', () {
    test('isAdmin returns true for admin role and false for non-admin', () {
      expect(policy.isAdmin(adminUser), isTrue);
      expect(policy.isAdmin(servantUser), isFalse);
      expect(policy.isAdmin(studentUser), isFalse);
      expect(policy.isAdmin(guestUser), isFalse);
    });

    test('canAccessAllData returns true only for admin', () {
      expect(policy.canAccessAllData(adminUser), isTrue);
      expect(policy.canAccessAllData(servantUser), isFalse);
      expect(policy.canAccessAllData(studentUser), isFalse);
      expect(policy.canAccessAllData(guestUser), isFalse);
    });

    test('canAccessAdminArea requires both admin role and fresh session', () {
      expect(
        policy.canAccessAdminArea(user: adminUser, isSessionFresh: true),
        isTrue,
      );
      expect(
        policy.canAccessAdminArea(user: adminUser, isSessionFresh: false),
        isFalse,
      );
      expect(
        policy.canAccessAdminArea(user: servantUser, isSessionFresh: true),
        isFalse,
      );
      expect(
        policy.canAccessAdminArea(user: studentUser, isSessionFresh: true),
        isFalse,
      );
      expect(
        policy.canAccessAdminArea(user: guestUser, isSessionFresh: true),
        isFalse,
      );
    });

    test(
      'permission guards return true for admin role and false for non-admin',
      () {
        expect(policy.canManageTeams(adminUser), isTrue);
        expect(policy.canManageTeams(servantUser), isFalse);
        expect(policy.canManageTeams(studentUser), isFalse);
        expect(policy.canManageTeams(guestUser), isFalse);

        expect(policy.canManageServants(adminUser), isTrue);
        expect(policy.canManageServants(servantUser), isFalse);
        expect(policy.canManageServants(studentUser), isFalse);
        expect(policy.canManageServants(guestUser), isFalse);

        expect(policy.canManageStudents(adminUser), isTrue);
        expect(policy.canManageStudents(servantUser), isFalse);
        expect(policy.canManageStudents(studentUser), isFalse);
        expect(policy.canManageStudents(guestUser), isFalse);

        expect(policy.canOpenDevTools(adminUser), isTrue);
        expect(policy.canOpenDevTools(servantUser), isFalse);
        expect(policy.canOpenDevTools(studentUser), isFalse);
        expect(policy.canOpenDevTools(guestUser), isFalse);
      },
    );
  });
}

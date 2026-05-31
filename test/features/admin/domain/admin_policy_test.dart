import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/admin/domain/admin_policy.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = AdminPolicy();

  const adminUser = AuthUser(
    uid: 'admin1',
    email: 'admin@example.com',
    name: 'Admin',
    role: UserRole.admin,
    isEmailVerified: true,
  );

  const servantUser = AuthUser(
    uid: 'servant1',
    email: 'servant@example.com',
    name: 'Servant',
    role: UserRole.servant,
    isEmailVerified: true,
  );

  const studentUser = AuthUser(
    uid: 'student1',
    email: 'student@example.com',
    name: 'Student',
    role: UserRole.student,
    isEmailVerified: true,
  );

  const guestUser = AuthUser(
    uid: 'viewer1',
    email: 'viewer@example.com',
    name: 'Viewer',
    role: UserRole.student,
    isEmailVerified: true,
  );

  group('AdminPolicy', () {
    test('isAdmin returns true only for admin role', () {
      expect(policy.isAdmin(adminUser), isTrue);
      expect(policy.isAdmin(servantUser), isFalse);
      expect(policy.isAdmin(studentUser), isFalse);
      expect(policy.isAdmin(guestUser), isFalse);
    });

    test('canAccessAllData returns true only for admin role', () {
      expect(policy.canAccessAllData(adminUser), isTrue);
      expect(policy.canAccessAllData(servantUser), isFalse);
      expect(policy.canAccessAllData(studentUser), isFalse);
      expect(policy.canAccessAllData(guestUser), isFalse);
    });

    test('canAccessAdminArea returns true only if admin AND fresh session', () {
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
    });

    test('canManageTeams returns true only for admin role', () {
      expect(policy.canManageTeams(adminUser), isTrue);
      expect(policy.canManageTeams(servantUser), isFalse);
      expect(policy.canManageTeams(studentUser), isFalse);
      expect(policy.canManageTeams(guestUser), isFalse);
    });

    test('canManageServants returns true only for admin role', () {
      expect(policy.canManageServants(adminUser), isTrue);
      expect(policy.canManageServants(servantUser), isFalse);
      expect(policy.canManageServants(studentUser), isFalse);
      expect(policy.canManageServants(guestUser), isFalse);
    });

    test('canManageStudents returns true only for admin role', () {
      expect(policy.canManageStudents(adminUser), isTrue);
      expect(policy.canManageStudents(servantUser), isFalse);
      expect(policy.canManageStudents(studentUser), isFalse);
      expect(policy.canManageStudents(guestUser), isFalse);
    });

    test('canOpenDevTools returns true only for admin role', () {
      expect(policy.canOpenDevTools(adminUser), isTrue);
      expect(policy.canOpenDevTools(servantUser), isFalse);
      expect(policy.canOpenDevTools(studentUser), isFalse);
      expect(policy.canOpenDevTools(guestUser), isFalse);
    });
  });
}

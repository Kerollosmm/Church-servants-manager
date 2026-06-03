import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUser extends Mock implements User {
  @override
  String get uid => '123';
  @override
  String? get email => 'test@example.com';
  @override
  String? get displayName => 'Test User';
  @override
  bool get emailVerified => true;
}

void main() {
  group('AuthUserModel.fromFirebaseToken', () {
    test('parses custom claims correctly for admin', () {
      final mockUser = MockUser();
      final claims = {
        'role': 'admin',
        'teams': ['teamA'],
      };
      final authUser = AuthUserModel.fromFirebaseToken(mockUser, claims);
      expect(authUser.role, UserRole.admin);
      expect(authUser.assignedTeamIds, ['teamA']);
    });

    test('parses custom claims correctly for servant', () {
      final mockUser = MockUser();
      final claims = {
        'role': 'servant',
        'teams': ['teamB'],
      };
      final authUser = AuthUserModel.fromFirebaseToken(mockUser, claims);
      expect(authUser.role, UserRole.servant);
      expect(authUser.assignedTeamIds, ['teamB']);
    });

    test('falls back to default role for missing or null role claim', () {
      final mockUser = MockUser();
      final authUserNullRole = AuthUserModel.fromFirebaseToken(mockUser, {
        'role': null,
      });
      expect(authUserNullRole.role, UserRole.student);

      final authUserMissingRole = AuthUserModel.fromFirebaseToken(mockUser, {});
      expect(authUserMissingRole.role, UserRole.student);
    });

    test(
      'falls back to default role for invalid role string without throwing',
      () {
        final mockUser = MockUser();
        final authUser = AuthUserModel.fromFirebaseToken(mockUser, {
          'role': 'invalid_role',
        });
        expect(authUser.role, UserRole.student);
      },
    );

    test('falls back to default role for non-string role claim type', () {
      final mockUser = MockUser();
      final authUser = AuthUserModel.fromFirebaseToken(mockUser, {'role': 123});
      expect(authUser.role, UserRole.student);
    });

    test('parses legacy singular assignedTeamId claim', () {
      final mockUser = MockUser();
      final claims = {'role': 'servant', 'assignedTeamId': 'legacy-team-1'};
      final authUser = AuthUserModel.fromFirebaseToken(mockUser, claims);
      expect(authUser.assignedTeamId, 'legacy-team-1');
      expect(authUser.effectiveAssignedTeamIds, ['legacy-team-1']);
    });

    test(
      'prefers assignedTeamIds but still includes assignedTeamId in effective list',
      () {
        final mockUser = MockUser();
        final claims = {
          'role': 'servant',
          'assignedTeamIds': ['new-team-1'],
          'assignedTeamId': 'legacy-team-1',
        };
        final authUser = AuthUserModel.fromFirebaseToken(mockUser, claims);
        expect(authUser.assignedTeamIds, contains('new-team-1'));
        expect(authUser.assignedTeamId, 'legacy-team-1');
        expect(
          authUser.effectiveAssignedTeamIds,
          containsAll(['new-team-1', 'legacy-team-1']),
        );
      },
    );

    test('handles missing or null teams claim', () {
      final mockUser = MockUser();
      final authUser = AuthUserModel.fromFirebaseToken(mockUser, {});
      expect(authUser.assignedTeamIds, isEmpty);

      final authUserNullTeams = AuthUserModel.fromFirebaseToken(mockUser, {
        'teams': null,
      });
      expect(authUserNullTeams.assignedTeamIds, isEmpty);
    });

    test('parses isArchived claim correctly', () {
      final mockUser = MockUser();
      final authUserArchived = AuthUserModel.fromFirebaseToken(mockUser, {
        'isArchived': true,
      });
      expect(authUserArchived.isArchived, true);

      final authUserNotArchived = AuthUserModel.fromFirebaseToken(mockUser, {
        'isArchived': false,
      });
      expect(authUserNotArchived.isArchived, false);

      final authUserMissingArchived = AuthUserModel.fromFirebaseToken(
        mockUser,
        {},
      );
      expect(authUserMissingArchived.isArchived, false);
    });
  });

  group('AuthUserModel.fromFirebaseUnsafe', () {
    test('creates AuthUserModel with temporary student role', () {
      final mockUser = MockUser();
      final authUser = AuthUserModel.fromFirebaseUnsafe(mockUser);

      expect(authUser.uid, '123');
      expect(authUser.email, 'test@example.com');
      expect(authUser.name, 'Test User');
      expect(authUser.role, UserRole.student); // Temporary default role
      expect(authUser.isEmailVerified, true);
    });
  });
}

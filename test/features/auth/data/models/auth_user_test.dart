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
  group('AuthUser.fromFirebaseToken', () {
    test('parses custom claims correctly for admin', () {
      final mockUser = MockUser();
      final claims = {
        'role': 'admin',
        'teams': ['teamA'],
      };
      final authUser = AuthUser.fromFirebaseToken(mockUser, claims);
      expect(authUser.role, UserRole.admin);
      expect(authUser.assignedTeamIds, ['teamA']);
    });
  });
}

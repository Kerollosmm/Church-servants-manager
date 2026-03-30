import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/auth_service.dart';
import 'package:church_management_system/features/auth/data/services/firebase_auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuthProvider extends Mock implements FirebaseAuthProvider {}

void main() {
  late MockFirebaseAuthProvider provider;
  late AuthService service;

  const createdUser = AuthUser(
    uid: 'user-1',
    email: 'user@test.com',
    name: 'User',
    role: UserRole.student,
  );

  setUp(() {
    provider = MockFirebaseAuthProvider();
    service = AuthService(provider: provider);
  });

  test(
    'signUp always creates student role even if admin role is requested',
    () async {
      when(
        () => provider.createUser(
          email: 'user@test.com',
          password: 'secret123',
          name: 'User',
          role: UserRole.student,
          grade: any(named: 'grade'),
        ),
      ).thenAnswer((_) async => createdUser);

      final result = await service.signUp(
        email: 'user@test.com',
        password: 'secret123',
        name: 'User',
        role: UserRole.admin,
      );

      expect(result.role, UserRole.student);
      verify(
        () => provider.createUser(
          email: 'user@test.com',
          password: 'secret123',
          name: 'User',
          role: UserRole.student,
          grade: null,
        ),
      ).called(1);
    },
  );
}

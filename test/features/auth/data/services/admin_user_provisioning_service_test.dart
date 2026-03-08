import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/admin_auth_client.dart';
import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
import 'package:church_management_system/features/auth/data/services/auth_user_profile_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminAuthClient extends Mock implements AdminAuthClient {}

class MockAuthUserProfileStore extends Mock implements AuthUserProfileStore {}

void main() {
  late MockAdminAuthClient adminAuthClient;
  late MockAuthUserProfileStore userProfileStore;
  late ClientAdminUserProvisioningService service;

  setUpAll(() {
    registerFallbackValue(
      AuthUser(
        uid: 'fallback',
        email: 'fallback@example.com',
        name: 'Fallback',
        role: UserRole.student,
        isEmailVerified: false,
      ),
    );
  });

  setUp(() {
    adminAuthClient = MockAdminAuthClient();
    userProfileStore = MockAuthUserProfileStore();
    service = ClientAdminUserProvisioningService(
      userProfileStore: userProfileStore,
      adminAuthClient: adminAuthClient,
    );
  });

  test('createUser persists created user profile via backend client', () async {
    const createdHandle = AdminAuthUserHandle('u1');

    when(
      () => adminAuthClient.createUser(
        email: 'new@example.com',
        password: 'secret123',
        name: 'New User',
        role: UserRole.student,
      ),
    ).thenAnswer((_) async => createdHandle);
    when(() => userProfileStore.saveUser(any())).thenAnswer((_) async {});

    final result = await service.createUser(
      email: 'new@example.com',
      password: 'secret123',
      name: 'New User',
      role: UserRole.student,
    );

    expect(result.uid, 'u1');
    verify(
      () => userProfileStore.saveUser(any(that: isA<AuthUser>())),
    ).called(1);
  });

  test('rollbackCreatedUser deletes profile through backend client', () async {
    when(
      () => adminAuthClient.rollbackCreatedUser(uid: 'u1'),
    ).thenAnswer((_) async {});
    when(() => userProfileStore.deleteUser('u1')).thenAnswer((_) async {});

    await service.rollbackCreatedUser(
      uid: 'u1',
      email: 'new@example.com',
      password: 'secret123',
    );

    verify(() => userProfileStore.deleteUser('u1')).called(1);
    verify(() => adminAuthClient.rollbackCreatedUser(uid: 'u1')).called(1);
  });
}

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/admin_auth_client.dart';
import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
import 'package:church_management_system/features/auth/data/services/auth_service.dart';
import 'package:church_management_system/features/auth/data/services/auth_user_profile_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminAuthClient extends Mock implements AdminAuthClient {}

class MockAuthUserProfileStore extends Mock implements AuthUserProfileStore {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAdminAuthClient adminAuthClient;
  late MockAuthUserProfileStore userProfileStore;
  late MockAuthService authService;
  late ClientAdminUserProvisioningService service;

  setUpAll(() {
    registerFallbackValue(
      AuthUser(
        uid: 'fallback',
        email: 'fallback@example.com',
        name: 'Fallback',
        role: UserRole.student,
      ),
    );
  });

  setUp(() {
    adminAuthClient = MockAdminAuthClient();
    userProfileStore = MockAuthUserProfileStore();
    authService = MockAuthService();
    service = ClientAdminUserProvisioningService(
      userProfileStore: userProfileStore,
      authService: authService,
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

  test('archiveUser archives linked user through backend client', () async {
    when(() => adminAuthClient.archiveUser(uid: 'u1')).thenAnswer((_) async {});
    when(
      () => userProfileStore.updateUserFields('u1', any()),
    ).thenAnswer((_) async {});

    await service.archiveUser(uid: 'u1');

    verify(() => adminAuthClient.archiveUser(uid: 'u1')).called(1);
    verify(() => userProfileStore.updateUserFields('u1', any())).called(1);
  });

  test('restoreUser restores auth account and sends reset email', () async {
    final restoredUser = AuthUser(
      uid: 'u1',
      email: 'restored@example.com',
      name: 'Restored',
      role: UserRole.servant,
      isEmailVerified: true,
      isArchived: true,
    );

    when(
      () => userProfileStore.fetchUser('u1'),
    ).thenAnswer((_) async => restoredUser);
    when(() => adminAuthClient.restoreUser(uid: 'u1')).thenAnswer((_) async {});
    when(
      () => userProfileStore.updateUserFields('u1', any()),
    ).thenAnswer((_) async {});
    when(
      () => authService.sendPasswordResetEmail('restored@example.com'),
    ).thenAnswer((_) async {});

    await service.restoreUser(uid: 'u1');

    verify(() => adminAuthClient.restoreUser(uid: 'u1')).called(1);
    verify(() => userProfileStore.updateUserFields('u1', any())).called(1);
    verify(
      () => authService.sendPasswordResetEmail('restored@example.com'),
    ).called(1);
  });
}

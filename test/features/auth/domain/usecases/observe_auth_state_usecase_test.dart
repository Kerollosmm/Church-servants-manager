import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/auth_service.dart';
import 'package:church_management_system/features/auth/domain/usecases/observe_auth_state_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService authService;
  late ObserveAuthStateUseCase useCase;

  setUp(() {
    authService = MockAuthService();
    useCase = ObserveAuthStateUseCase(authService);
  });

  test('resolveError blocks degraded admin access when refresh fails', () {
    const cached = AuthUser(
      uid: 'admin-1',
      email: 'admin@test.com',
      name: 'Admin',
      role: UserRole.admin,
      isEmailVerified: true,
    );

    when(() => authService.currentUser).thenReturn(cached);
    when(() => authService.lastKnownAppUser).thenReturn(cached);

    final resolution = useCase.resolveError(fallbackErrorMessage: 'fallback');

    expect(resolution.status, AuthSessionStatus.error);
    expect(
      resolution.message,
      ObserveAuthStateUseCase.privilegedRefreshRequiredMessage,
    );
  });

  test('resolveError still allows degraded student fallback', () {
    const cached = AuthUser(
      uid: 'student-1',
      email: 'student@test.com',
      name: 'Student',
      role: UserRole.student,
      isEmailVerified: true,
    );

    when(() => authService.currentUser).thenReturn(cached);
    when(() => authService.lastKnownAppUser).thenReturn(cached);

    final resolution = useCase.resolveError(fallbackErrorMessage: 'fallback');

    expect(resolution.status, AuthSessionStatus.degraded);
    expect(resolution.user, cached);
  });
}

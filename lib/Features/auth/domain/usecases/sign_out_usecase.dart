import 'package:church_management_system/features/auth/domain/repos/auth_repository.dart';

// FIX [P1]: extracted auth sign-out orchestration behind a use case.
class SignOutUseCase {
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() {
    return _repository.signOut();
  }
}

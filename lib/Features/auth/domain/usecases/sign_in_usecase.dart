import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/domain/repos/auth_repository.dart';

// FIX [P1]: extracted auth sign-in orchestration behind a use case.
class SignInUseCase {
  const SignInUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call({required String email, required String password}) {
    return _repository.signIn(email: email, password: password);
  }
}

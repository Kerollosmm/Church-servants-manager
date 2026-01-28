import 'package:csms/Features/auth/domain/repositories/auth_repository.dart';
import 'package:csms/core/constants/enums.dart';
import 'package:csms/core/models/user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// States
sealed class AuthCubitState {
  const AuthCubitState();
}

class AuthCubitInitial extends AuthCubitState {
  const AuthCubitInitial();
}

class AuthCubitLoading extends AuthCubitState {
  const AuthCubitLoading();
}

class AuthCubitAuthenticated extends AuthCubitState {
  final AppUser user;
  const AuthCubitAuthenticated(this.user);
}

class AuthCubitError extends AuthCubitState {
  final String message;
  const AuthCubitError(this.message);
}

// Cubit
class AuthCubit extends Cubit<AuthCubitState> {
  final AuthRepository _authRepository;

  AuthCubit({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthCubitInitial());

  Future<void> login({required String email, required String password}) async {
    emit(const AuthCubitLoading());
    try {
      final user = await _authRepository.signIn(
        email: email,
        password: password,
      );
      emit(AuthCubitAuthenticated(user));
    } catch (e) {
      emit(AuthCubitError(e.toString()));
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    emit(const AuthCubitLoading());
    try {
      final user = await _authRepository.signUp(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      emit(AuthCubitAuthenticated(user));
    } catch (e) {
      emit(AuthCubitError(e.toString()));
    }
  }

  void reset() {
    emit(const AuthCubitInitial());
  }
}

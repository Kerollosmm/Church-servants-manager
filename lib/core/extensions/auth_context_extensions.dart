import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension AuthContextExtension on BuildContext {
  /// Resolves the currently authenticated or degraded [AuthUser] actor from [AuthBloc], or returns null.
  AuthUser? get currentActorOrNull => read<AuthBloc>().state.currentActorOrNull;
}

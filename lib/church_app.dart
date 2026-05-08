import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/features/auth/domain/repos/auth_repository.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/auth/presentation/widgets/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChurchApp extends StatelessWidget {
  const ChurchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              AuthBloc(authService: getIt<AuthRepository>())
                ..add(const AuthEventCheckStatus()),
        ),
      ],
      // AuthGate handles downstream routing, MaterialApps, and feature-scoped Blocs.
      child: const AuthGate(),
    );
  }
}

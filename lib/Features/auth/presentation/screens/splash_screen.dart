import 'package:church_management_system/core/routing/role_router.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/auth/presentation/screens/login_screen.dart';
import 'package:church_management_system/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthBloc>().add(const AuthEventCheckStatus());
    });
  }

  void _navigate(AuthState state) {
    final destination = switch (state) {
      AuthAuthenticated(:final user) ||
      AuthDegraded(:final user) => RoleRouter.resolve(user.role, state),
      AuthArchived(:final message, :final email) => ArchivedAccountScreen(
        message: message,
        email: email,
      ),
      AuthNeedsVerification() => const VerifyEmailScreen(),
      _ => const LoginScreen(),
    };

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous is AuthInitial &&
          current is! AuthInitial &&
          current is! AuthLoading,
      listener: (context, state) => _navigate(state),
      child: const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

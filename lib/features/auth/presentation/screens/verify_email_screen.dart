import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:church_managment_system/core/theme/app_spacing.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 100,
                color: AppColors.primary,
              ),
              AppSpacing.gapLg,
              Text(
                'Verify Your Email',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapMd,
              Text(
                'We have sent a verification link to your email. Please check your inbox and click the link to continue.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapXl,
              FilledButton.icon(
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthEventCheckStatus());
                },
                icon: const Icon(Icons.refresh),
                label: const Text('I have verified my email'),
              ),
              AppSpacing.gapMd,
              OutlinedButton.icon(
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthEventSendVerification());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verification email resent')),
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text('Resend verification email'),
              ),
              AppSpacing.gapLg,
              TextButton(
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthEventSignOut());
                },
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:church_managment_system/core/theme/app_spacing.dart';
import 'package:church_managment_system/core/widgets/feedback/app_snackbars.dart';
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
                'تحقق من بريدك الإلكتروني',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapMd,
              Text(
                'أرسلنا رابط التحقق إلى بريدك الإلكتروني. افتح بريدك واضغط على الرابط للمتابعة.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapXl,
              FilledButton.icon(
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthEventCheckStatus());
                },
                icon: const Icon(Icons.refresh),
                label: const Text('لقد قمت بالتحقق من البريد'),
              ),
              AppSpacing.gapMd,
              OutlinedButton.icon(
                onPressed: () {
                  context.read<AuthBloc>().add(
                    const AuthEventSendVerification(),
                  );
                  AppSnackbars.showInfo(
                    context,
                    'تمت إعادة إرسال رسالة التحقق.',
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text('إعادة إرسال رسالة التحقق'),
              ),
              AppSpacing.gapLg,
              TextButton(
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthEventSignOut());
                },
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

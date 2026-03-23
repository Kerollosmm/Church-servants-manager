import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/core/widgets/dialogs/error_dialog.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/auth/presentation/widgets/email_verification_dialog.dart';
import 'package:church_management_system/features/auth/presentation/widgets/register_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  void _submit(
    BuildContext context,
    String name,
    String email,
    String password,
  ) {
    // FIX [P2]: Keep bloc interaction in the screen and move field state into RegisterForm.
    context.read<AuthBloc>().add(
      AuthEventSignUp(
        email: email,
        password: password,
        name: name,
        role: UserRole.student,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
          if (state is AuthNeedsVerification) {
            showEmailVerificationDialog(context);
          }
          if (state is AuthVerificationSent) {
            AppSnackbars.showSuccess(
              context,
              'تم إرسال رسالة التحقق إلى بريدك الإلكتروني.',
            );
          }
          if (state is AuthError) {
            showErrorDialog(context, state.message);
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              // FIX [P2]: Keep register screen focused on auth state side effects.
              child: RegisterForm(
                onSubmit: (name, email, password) =>
                    _submit(context, name, email, password),
                onSignIn: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

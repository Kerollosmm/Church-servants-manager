import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/utils/validators.dart';
import 'package:church_management_system/core/widgets/atoms/app_input_field.dart';
import 'package:church_management_system/core/widgets/atoms/app_primary_button.dart';
import 'package:church_management_system/core/widgets/atoms/app_text_button.dart';
import 'package:church_management_system/core/widgets/molecules/app_section_card.dart';
import 'package:church_management_system/core/widgets/organisms/app_header.dart';
import 'package:church_management_system/core/widgets/organisms/app_screen_shell.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/auth/presentation/widgets/email_verification_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _submit(BuildContext context, String email, String password) {
    context.read<AuthBloc>().add(
      AuthEventSignIn(email: email, password: password),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is AuthNeedsVerification ||
          current is AuthVerificationSent ||
          current is AuthAuthenticated ||
          current is AuthDegraded,
      listener: (context, state) {
        if (state is AuthNeedsVerification) {
          showEmailVerificationDialog(context);
        }
      },
      builder: (context, state) {
        final errorMessage = state is AuthError ? state.message : null;
        final isSubmitting = state is AuthLoading;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: AppScreenShell(
            body: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const AppHeader(
                              title: 'الكنيسة',
                              subtitle: 'نظام إدارة كنسي حديث',
                              showLogo: true,
                              enableLogoHero: true,
                            ),
                            const SizedBox(height: 24),
                            AppSectionCard(
                              child: _LoginForm(
                                isSubmitting: isSubmitting,
                                errorMessage: errorMessage,
                                onSubmit: (email, password) =>
                                    _submit(context, email, password),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({
    required this.isSubmitting,
    required this.errorMessage,
    required this.onSubmit,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final void Function(String email, String password) onSubmit;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void didUpdateWidget(covariant _LoginForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorMessage != null &&
        oldWidget.errorMessage != widget.errorMessage) {
      _passwordController.clear();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.onSubmit(_emailController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'مرحبا بعودتك',
            style: theme.textTheme.displayLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'سجّل الدخول للمتابعة إلى خدمات الكنيسة.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppInputField(
            label: 'البريد الإلكتروني',
            hint: 'name@example.com',
            leadingIcon: Icons.email_outlined,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: Validators.validateEmailArabic,
          ),
          const SizedBox(height: 16),
          AppInputField(
            label: 'كلمة المرور',
            hint: '........',
            leadingIcon: Icons.lock_outline,
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            validator: Validators.validatePasswordArabic,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AppTextButton(
              label: 'نسيت كلمة المرور؟',
              onPressed: () => Navigator.pushNamed(context, forgotPassword),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AppPrimaryButton(
              label: 'تسجيل الدخول',
              isLoading: widget.isSubmitting,
              onPressed: _handleSubmit,
            ),
          ),
          if (widget.errorMessage != null) ...[
            const SizedBox(height: 16),
            _LoginError(message: widget.errorMessage!),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('ليس لديك حساب؟', style: theme.textTheme.bodyMedium),
              AppTextButton(
                label: 'إنشاء حساب',
                onPressed: () => Navigator.pushNamed(context, register),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoginError extends StatelessWidget {
  const _LoginError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsetsDirectional.only(top: 2),
          child: Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.redAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

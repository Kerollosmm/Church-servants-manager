import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/utils/validators.dart';
import 'package:church_management_system/core/widgets/app_logo.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/core/widgets/gradient_border_container.dart';

import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:church_management_system/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:church_management_system/features/auth/presentation/widgets/email_verification_dialog.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
      AuthEventSignIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            current is AuthError ||
            current is AuthNeedsVerification ||
            current is AuthVerificationSent,
        listener: (context, state) {
          if (state is AuthError) {
            // Clear password for security — never keep a wrong password in the field.
            _passwordController.clear();
            AppSnackbars.showError(
              context,
              state.message,
              duration: const Duration(seconds: 4),
            );
          }
          if (state is AuthNeedsVerification) {
            showEmailVerificationDialog(context);
          }
          if (state is AuthVerificationSent) {
            AppSnackbars.showSuccess(
              context,
              'تم إرسال رسالة التحقق. راجع بريدك الإلكتروني.',
            );
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Column(
                children: [
                  // Logo
                  const AppLogo(size: 150),
                  AppSpacing.gapMd,

                  // App Title
                  Text(
                    'CSMS',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.tertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.gapXl,

                  // Form inside gradient container
                  GradientBorderContainer(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'مرحبا بعودتك',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.tertiary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'سجّل الدخول للمتابعة',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          AppSpacing.gapXl,

                          // Email
                          AuthTextField(
                            controller: _emailController,
                            label: 'البريد الإلكتروني',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.validateEmailArabic,
                          ),
                          AppSpacing.gapMd,

                          // Password
                          AuthTextField(
                            controller: _passwordController,
                            label: 'كلمة المرور',
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: Validators.validatePasswordArabic,
                          ),
                          AppSpacing.gapSm,

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, forgotPassword);
                              },
                              child: const Text('هل نسيت كلمة المرور؟'),
                            ),
                          ),
                          AppSpacing.gapMd,

                          // Submit
                          AuthSubmitButton(
                            text: 'تسجيل الدخول',
                            onPressed: _submit,
                          ),
                          AppSpacing.gapLg,

                          // Navigate to Register
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'ليس لديك حساب؟',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, register);
                                },
                                child: const Text('إنشاء حساب'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

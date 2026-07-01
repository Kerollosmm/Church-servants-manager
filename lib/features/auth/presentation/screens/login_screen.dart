import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/utils/validators.dart';
import 'package:church_management_system/core/widgets/app_logo.dart';
import 'package:church_management_system/core/widgets/common/ochre_button.dart';
import 'package:church_management_system/core/widgets/common/ochre_text_field.dart';
import 'package:church_management_system/core/widgets/common/sanctuary_background.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/auth/presentation/widgets/email_verification_dialog.dart';
import 'package:church_management_system/features/auth/presentation/widgets/ochre_auth_card.dart';
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

  // Use ValueNotifiers for localized rebuilds (performance optimization)
  final _obscurePassword = ValueNotifier<bool>(true);
  final _rememberMe = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _obscurePassword.dispose();
    _rememberMe.dispose();
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
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            current is AuthError ||
            current is AuthNeedsVerification ||
            current is AuthVerificationSent,
        listener: (context, state) {
          if (state is AuthError) {
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
        child: SanctuaryBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: OchreAuthCard(
                    header: Column(
                      children: [
                        const AppLogo(size: 130),
                        AppSpacing.gapMd,
                        Text(
                          'نظام إدارة الكنيسة',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'مرحباً بك مجدداً، يرجى تسجيل الدخول',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    body: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email
                          OchreTextField(
                            controller: _emailController,
                            label: 'البريد الإلكتروني',
                            placeholder: 'example@church.com',
                            prefixIcon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.validateEmailArabic,
                          ),
                          AppSpacing.gapLg,

                          // Password
                          ValueListenableBuilder<bool>(
                            valueListenable: _obscurePassword,
                            builder: (context, isObscured, _) {
                              return OchreTextField(
                                controller: _passwordController,
                                label: 'كلمة المرور',
                                placeholder: '••••••••',
                                prefixIcon: Icons.lock_outline,
                                obscureText: isObscured,
                                validator: Validators.validatePasswordArabic,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isObscured
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textTertiary,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _obscurePassword.value = !isObscured,
                                ),
                              );
                            },
                          ),

                          // Forgot Password link (positioned as per design)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, forgotPassword);
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'نسيت كلمة المرور؟',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          AppSpacing.gapXl,

                          // Submit Button
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              return OchreButton(
                                text: 'تسجيل الدخول',
                                icon: Icons.login,
                                isLoading: state is AuthLoading,
                                onPressed: state is AuthLoading
                                    ? null
                                    : _submit,
                              );
                            },
                          ),
                          AppSpacing.gapXl,

                          // Register Link
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'ليس لديك حساب؟',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, register);
                                },
                                child: const Text(
                                  'إنشاء حساب جديد',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/utils/validators.dart';
import 'package:church_management_system/core/widgets/app_logo.dart';
import 'package:church_management_system/core/widgets/common/ochre_button.dart';
import 'package:church_management_system/core/widgets/common/ochre_text_field.dart';
import 'package:church_management_system/core/widgets/common/sanctuary_background.dart';
import 'package:church_management_system/core/widgets/dialogs/error_dialog.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/auth/presentation/widgets/email_verification_dialog.dart';
import 'package:church_management_system/features/auth/presentation/widgets/ochre_auth_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Performance optimization: use ValueNotifier instead of setState
  final _obscurePassword = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _obscurePassword.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
      AuthEventSignUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
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
                        const AppLogo(size: 100),
                        AppSpacing.gapSm,
                        Text(
                          'إنشاء حساب جديد',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'سجّل الآن للبدء في استخدام النظام',
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
                          // Name
                          OchreTextField(
                            controller: _nameController,
                            label: 'الاسم الكامل',
                            placeholder: 'أدخل اسمك بالكامل',
                            prefixIcon: Icons.person_outline,
                            validator: Validators.validateNameArabic,
                          ),
                          AppSpacing.gapLg,

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
                                placeholder: 'أدخل كلمة مرور قوية',
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
                          AppSpacing.gapXl,

                          // Submit Button
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              return OchreButton(
                                text: 'إنشاء حساب',
                                icon: Icons.person_add_outlined,
                                isLoading: state is AuthLoading,
                                onPressed: _submit,
                              );
                            },
                          ),
                          AppSpacing.gapXl,

                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'لديك حساب بالفعل؟',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'تسجيل الدخول',
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

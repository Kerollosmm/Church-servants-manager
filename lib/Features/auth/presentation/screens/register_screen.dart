import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/utils/validators.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/core/widgets/dialogs/error_dialog.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:church_management_system/features/auth/presentation/widgets/auth_header.dart';
import 'package:church_management_system/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:church_management_system/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:church_management_system/features/auth/presentation/widgets/email_verification_dialog.dart';
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

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
      AuthEventSignUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: UserRole.student,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              child: AuthFormCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthHeader(
                        title: 'إنشاء حساب',
                        subtitle: 'سجّل الآن للبدء',
                      ),
                      AppSpacing.gapXl,

                      AuthTextField(
                        controller: _nameController,
                        label: 'الاسم الكامل',
                        prefixIcon: Icons.person_outline,
                        validator: Validators.validateNameArabic,
                      ),
                      AppSpacing.gapMd,

                      AuthTextField(
                        controller: _emailController,
                        label: 'البريد الإلكتروني',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmailArabic,
                      ),
                      AppSpacing.gapMd,

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
                      AppSpacing.gapLg,

                      AuthSubmitButton(
                        text: 'إنشاء حساب',
                        onPressed: _submit,
                      ),
                      AppSpacing.gapLg,

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'لديك حساب بالفعل؟',
                            style: theme.textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('تسجيل الدخول'),
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
    );
  }
}

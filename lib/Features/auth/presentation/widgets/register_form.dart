import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/utils/validators.dart';
import 'package:church_management_system/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:church_management_system/features/auth/presentation/widgets/auth_header.dart';
import 'package:church_management_system/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:church_management_system/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({
    super.key,
    required this.onSubmit,
    required this.onSignIn,
  });

  final void Function(String name, String email, String password) onSubmit;
  final VoidCallback onSignIn;

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthFormCard(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeader(title: 'إنشاء حساب', subtitle: 'سجّل الآن للبدء'),
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
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
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
            AuthSubmitButton(text: 'إنشاء حساب', onPressed: _submit),
            AppSpacing.gapLg,
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('لديك حساب بالفعل؟', style: theme.textTheme.bodyMedium),
                TextButton(
                  onPressed: widget.onSignIn,
                  child: const Text('تسجيل الدخول'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

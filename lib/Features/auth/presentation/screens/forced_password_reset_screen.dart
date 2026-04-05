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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ForcedPasswordResetScreen extends StatefulWidget {
  const ForcedPasswordResetScreen({super.key});

  @override
  State<ForcedPasswordResetScreen> createState() =>
      _ForcedPasswordResetScreenState();
}

class _ForcedPasswordResetScreenState extends State<ForcedPasswordResetScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
      AuthEventForcePasswordReset(newPassword: _newPasswordController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: GradientBorderContainer(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(),
                    AppSpacing.gapLg,
                    const Text(
                      'إعادة تعيين كلمة المرور',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    AppSpacing.gapSm,
                    const Text(
                      'تم إعادة تعيين كلمة المرور الخاصة بك. الرجاء تعيين كلمة مرور جديدة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.secondary),
                    ),
                    AppSpacing.gapLg,
                    AuthTextField(
                      controller: _newPasswordController,
                      label: 'كلمة المرور الجديدة',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureNewPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                      validator: Validators.validatePassword,
                    ),
                    AppSpacing.gapMd,
                    AuthTextField(
                      controller: _confirmPasswordController,
                      label: 'تأكيد كلمة المرور',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        final error = Validators.validatePassword(value);
                        if (error != null) return error;
                        if (value != _newPasswordController.text) {
                          return 'كلمتا المرور غير متطابقتين';
                        }
                        return null;
                      },
                    ),
                    AppSpacing.gapLg,
                    BlocListener<AuthBloc, AuthState>(
                      listener: (context, state) {
                        if (state is AuthPasswordResetSuccess) {
                          AppSnackbars.showSuccess(
                            context,
                            'تم تغيير كلمة المرور بنجاح',
                          );
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            login,
                            (route) => false,
                          );
                        } else if (state is AuthError) {
                          AppSnackbars.showError(context, state.message);
                        }
                      },
                      child: AuthSubmitButton(
                        onPressed: _submit,
                        text: 'تغيير كلمة المرور',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

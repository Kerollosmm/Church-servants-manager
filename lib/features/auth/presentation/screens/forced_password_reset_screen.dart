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
import 'package:church_management_system/features/auth/presentation/widgets/ochre_auth_card.dart';
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

  // Performance optimization: use ValueNotifier instead of setState
  final _obscureNewPassword = ValueNotifier<bool>(true);
  final _obscureConfirmPassword = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _obscureNewPassword.dispose();
    _obscureConfirmPassword.dispose();
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
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordResetSuccess) {
            AppSnackbars.showSuccess(context, 'تم تغيير كلمة المرور بنجاح');
            Navigator.pushNamedAndRemoveUntil(context, login, (route) => false);
          } else if (state is AuthError) {
            AppSnackbars.showError(context, state.message);
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
                          'تغيير كلمة المرور',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'تم إعادة تعيين كلمة المرور الخاصة بك.\nالرجاء تعيين كلمة مرور جديدة.',
                          textAlign: TextAlign.center,
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
                          // New Password
                          ValueListenableBuilder<bool>(
                            valueListenable: _obscureNewPassword,
                            builder: (context, isObscured, _) {
                              return OchreTextField(
                                controller: _newPasswordController,
                                label: 'كلمة المرور الجديدة',
                                placeholder: 'أدخل كلمة المرور الجديدة',
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
                                      _obscureNewPassword.value = !isObscured,
                                ),
                              );
                            },
                          ),
                          AppSpacing.gapLg,

                          // Confirm Password
                          ValueListenableBuilder<bool>(
                            valueListenable: _obscureConfirmPassword,
                            builder: (context, isObscured, _) {
                              return OchreTextField(
                                controller: _confirmPasswordController,
                                label: 'تأكيد كلمة المرور',
                                placeholder: 'أعد إدخال كلمة المرور',
                                prefixIcon: Icons.lock_outline,
                                obscureText: isObscured,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isObscured
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textTertiary,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _obscureConfirmPassword.value =
                                          !isObscured,
                                ),
                                validator: (value) {
                                  final error =
                                      Validators.validatePasswordArabic(value);
                                  if (error != null) return error;
                                  if (value != _newPasswordController.text) {
                                    return 'كلمتا المرور غير متطابقتين';
                                  }
                                  return null;
                                },
                              );
                            },
                          ),
                          AppSpacing.gapXl,

                          // Submit Button
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              return OchreButton(
                                text: 'تغيير كلمة المرور',
                                icon: Icons.update_outlined,
                                isLoading: state is AuthLoading,
                                onPressed: state is AuthLoading
                                    ? null
                                    : _submit,
                              );
                            },
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

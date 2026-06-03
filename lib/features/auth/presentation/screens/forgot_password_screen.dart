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
import 'package:church_management_system/features/auth/presentation/widgets/ochre_auth_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
      AuthEventForgotPassword(email: _emailController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordResetSent) {
            AppSnackbars.showSuccess(
              context,
              'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك.',
            );
            Navigator.pop(context);
          }
          if (state is AuthError) {
            showErrorDialog(context, state.message);
          }
        },
        child: SanctuaryBackground(
          child: SafeArea(
            child: Stack(
              children: [
                // Back Button
                Positioned(
                  top: 10,
                  right: 10, // RTL
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_forward,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Center(
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
                              'إعادة تعيين كلمة المرور',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
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
                              AppSpacing.gapXl,

                              // Submit Button
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  return OchreButton(
                                    text: 'إرسال رابط إعادة التعيين',
                                    icon: Icons.send_outlined,
                                    isLoading: state is AuthLoading,
                                    onPressed: _submit,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

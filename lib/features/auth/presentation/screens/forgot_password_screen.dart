import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/utils/validators.dart';
import 'package:church_management_system/core/widgets/dialogs/error_dialog.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:church_management_system/features/auth/presentation/widgets/auth_header.dart';
import 'package:church_management_system/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:church_management_system/features/auth/presentation/widgets/auth_text_field.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                        title: 'إعادة تعيين كلمة المرور',
                        subtitle:
                            'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين',
                      ),
                      AppSpacing.gapXl,

                      AuthTextField(
                        controller: _emailController,
                        label: 'البريد الإلكتروني',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmailArabic,
                      ),
                      AppSpacing.gapLg,

                      AuthSubmitButton(
                        text: 'إرسال رابط إعادة التعيين',
                        onPressed: _submit,
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

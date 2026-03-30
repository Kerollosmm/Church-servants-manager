import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// FIX [015] Gating screen shown to restored accounts that must change their
// temporary password before accessing the app. The user cannot navigate away
// until the password is updated and their session is refreshed.
class ForcePasswordResetScreen extends StatefulWidget {
  const ForcePasswordResetScreen({super.key});

  @override
  State<ForcePasswordResetScreen> createState() =>
      _ForcePasswordResetScreenState();
}

class _ForcePasswordResetScreenState extends State<ForcePasswordResetScreen> {
  final _emailController = TextEditingController();
  bool _emailSent = false;
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    setState(() => _isSending = true);
    final bloc = context.read<AuthBloc>();
    final currentState = bloc.state;
    final email = switch (currentState) {
      AuthPendingPasswordReset(:final user) => user.email,
      _ => '',
    };
    bloc.add(AuthEventForgotPassword(email: email));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isSending = false;
        _emailSent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      // FIX [015] Prevent back-navigation: the user MUST change their password.
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Icon(
                  Icons.lock_reset_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'تغيير كلمة المرور مطلوب',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'تم استعادة حسابك. يجب عليك تغيير كلمة المرور المؤقتة قبل المتابعة.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_emailSent)
                  Card(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: _isSending ? null : _sendResetEmail,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.email_outlined),
                    label: Text(
                      _isSending
                          ? 'جارٍ الإرسال...'
                          : 'إرسال رابط تغيير كلمة المرور',
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      context.read<AuthBloc>().add(const AuthEventSignOut()),
                  child: Text(
                    'تسجيل الخروج',
                    style: TextStyle(color: theme.colorScheme.error),
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

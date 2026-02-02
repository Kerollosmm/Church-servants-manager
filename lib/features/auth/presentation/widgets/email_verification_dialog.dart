
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows email verification dialog
void showEmailVerificationDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.mark_email_unread, color: Colors.orange),
          SizedBox(width: 8),
          Text('Verify Your Email'),
        ],
      ),
      content: const Text(
        'We have sent a verification link to your email address. '
        'Please check your inbox and click the link to verify your account.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('OK'),
        ),
        FilledButton.icon(
          onPressed: () {
            context.read<AuthBloc>().add(const AuthEventSendVerification());
            Navigator.pop(dialogContext);
          },
          icon: const Icon(Icons.send),
          label: const Text('Resend Email'),
        ),
      ],
    ),
  );
}

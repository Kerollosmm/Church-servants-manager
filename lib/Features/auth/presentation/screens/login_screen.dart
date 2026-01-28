import 'package:csms/Features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/core/constants/enums.dart';
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
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSignupMode = false;
  UserRole _selectedRole = UserRole.student;
  bool _obscurePassword = true;
  bool _verificationDialogShowing = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Check if we need to show verification dialog on load
    final state = context.watch<AuthBloc>().state;
    if (state is AuthNeedsVerification && !_verificationDialogShowing) {
      _verificationDialogShowing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showVerificationDialog(context);
      });
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // Show dialog for email verification (handled by build check as well, but this catches transitions)
          if (state is AuthNeedsVerification && !_verificationDialogShowing) {
            _verificationDialogShowing = true;
            _showVerificationDialog(context);
          }
          // Reset flag if state changes away from needs verification
          if (state is! AuthNeedsVerification) {
            _verificationDialogShowing = false;
          }
          // Show snackbar for verification sent
          if (state is AuthVerificationSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verification email sent! Check your inbox.'),
                backgroundColor: Colors.green,
              ),
            );
          }
          // Show snackbar for errors
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo/Title
                        Icon(
                          Icons.church_rounded,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isSignupMode ? 'Create Account' : 'Welcome Back',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isSignupMode
                              ? 'Sign up to get started'
                              : 'Sign in to continue',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Name (signup only)
                        if (_isSignupMode) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (_isSignupMode &&
                                  (value == null || value.isEmpty)) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            }
                            if (!value.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
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
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Role (signup only)
                        if (_isSignupMode) ...[
                          DropdownButtonFormField<UserRole>(
                            value: _selectedRole,
                            decoration: InputDecoration(
                              labelText: 'Role',
                              prefixIcon: const Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: UserRole.student,
                                child: Text('Student'),
                              ),
                              DropdownMenuItem(
                                value: UserRole.servant,
                                child: Text('Servant'),
                              ),
                            ],
                            onChanged: (role) {
                              if (role != null) {
                                setState(() => _selectedRole = role);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        const SizedBox(height: 8),

                        // Submit Button
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final isLoading = state is AuthLoading;

                            return FilledButton(
                              onPressed: isLoading ? null : _submit,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isSignupMode ? 'Sign Up' : 'Login',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Toggle mode
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isSignupMode
                                  ? 'Already have an account?'
                                  : "Don't have an account?",
                              style: theme.textTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isSignupMode = !_isSignupMode;
                                });
                              },
                              child: Text(_isSignupMode ? 'Login' : 'Sign Up'),
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
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final bloc = context.read<AuthBloc>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isSignupMode) {
      bloc.add(
        AuthEventSignUp(
          email: email,
          password: password,
          name: _nameController.text.trim(),
          role: _selectedRole.name,
        ),
      );
    } else {
      bloc.add(AuthEventSignIn(email: email, password: password));
    }
  }

  void _showVerificationDialog(BuildContext context) {
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
            onPressed: () {
              Navigator.pop(dialogContext);
            },
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
}

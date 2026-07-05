import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/core/routing/app_router.dart';
import 'package:church_management_system/core/services/lifecycle_sync_manager.dart';
import 'package:church_management_system/core/theme/app_theme.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/auth/presentation/screens/forced_password_reset_screen.dart';
import 'package:church_management_system/features/auth/presentation/screens/login_screen.dart';
import 'package:church_management_system/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:church_management_system/features/servant/presentation/screens/servant_dashboard_screen.dart';
import 'package:church_management_system/features/student/presentation/screens/student_profile_screen.dart';
import 'package:church_management_system/role_user_route.dart';
import 'package:church_management_system/shared/widgets/offline_indicator.dart';
import 'package:church_management_system/shared/widgets/sync_status_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:church_management_system/l10n/app_localizations.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  bool _isAuthenticatedState(AuthState state) =>
      state is AuthAuthenticated || state is AuthDegraded;

  Widget _buildAuthenticatedApp(BuildContext context, AuthState state) {
    final user = state is AuthAuthenticated
        ? state.user
        : (state as AuthDegraded).user;

    Widget homeWidget = const SizedBox.shrink();

    switch (user.role) {
      case UserRole.servant:
      case UserRole.admin:
        homeWidget = user.role == UserRole.admin
            ? (state is AuthAuthenticated
                  ? const AdminDashboardScreen()
                  : _AdminRefreshRequiredScreen(
                      message: (state as AuthDegraded).message,
                    ))
            : ServantDashboardScreen(user: user);
        break;
      case UserRole.student:
        homeWidget = StudentProfileScreen(user: user);
        break;
    }

    return RoleUserRoute(
      user: user,
      child: LifecycleSyncManager(
        child: MaterialApp(
          title: 'اعداد خدام',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateRoute: getIt<AppRouter>().onGenerateRoute,
          home: homeWidget,
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  const OfflineIndicator(),
                  const SyncStatusIndicator(),
                  Expanded(child: child ?? const SizedBox.shrink()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        if (current is! AuthDegraded) return false;
        if (!_isAuthenticatedState(previous)) return false;
        if (previous is AuthDegraded) {
          return previous.message != current.message;
        }
        return true;
      },
      listener: (context, state) {
        if (state is AuthDegraded) {
          AppSnackbars.showInfo(context, state.message);
        } else if (state is AuthRoleUpdated) {
          AppSnackbars.showSuccess(context, 'تم تحديث صلاحيات الحساب بنجاح.');
        }
      },
      builder: (context, state) {
        // Loading state
        if (state is AuthLoading ||
            state is AuthSigningOut ||
            state is AuthRoleRefreshing) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (state is AuthArchived) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            home: _ArchivedAccountScreen(
              message: state.message,
              email: state.email,
            ),
          );
        }

        // Authenticated - route based on role with scoped MultiBlocProvider
        if (state is AuthAuthenticated || state is AuthDegraded) {
          return _buildAuthenticatedApp(context, state);
        }

        // Needs verification
        if (state is AuthNeedsVerification) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            home: const VerifyEmailScreen(),
          );
        }

        // Needs forced password reset
        if (state is AuthNeedsPasswordReset) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            home: const ForcedPasswordResetScreen(),
          );
        }

        // Unauthenticated
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          onGenerateRoute: getIt<AppRouter>().onGenerateRoute,
          home: const LoginScreen(),
        );
      },
    );
  }
}

class _AdminRefreshRequiredScreen extends StatelessWidget {
  final String message;

  const _AdminRefreshRequiredScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تحديث الوصول للمسؤول')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.admin_panel_settings_outlined, size: 56),
              const SizedBox(height: 12),
              const Text(
                'يرجى مزامنة البيانات للحصول على كامل صلاحيات المسؤول.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthEventRefreshUser());
                },
                icon: const Icon(Icons.sync),
                label: const Text('مزامنة الوصول'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthEventSignOut());
                },
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchivedAccountScreen extends StatelessWidget {
  const _ArchivedAccountScreen({required this.message, this.email});

  final String message;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الحساب غير متاح')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_person_outlined, size: 56),
              const SizedBox(height: 12),
              const Text(
                'عذراً، الوصول لهذا الحساب متوقف حالياً.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              if (email != null && email!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(email!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthEventSignOut());
                },
                child: const Text('العودة لتسجيل الدخول'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

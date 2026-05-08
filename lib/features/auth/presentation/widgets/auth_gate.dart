import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/core/routing/app_router.dart';
import 'package:church_management_system/core/theme/app_theme.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/auth/presentation/screens/forced_password_reset_screen.dart';
import 'package:church_management_system/features/auth/presentation/screens/login_screen.dart';
import 'package:church_management_system/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:church_management_system/features/servant/domain/repos/i_servant_repository.dart';
import 'package:church_management_system/features/servant/domain/usecases/provision_servant_with_auth_usecase.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_data/servant_data_bloc.dart';
import 'package:church_management_system/features/servant/presentation/screens/servant_dashboard_screen.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_list_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/provision_student_with_auth_usecase.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_profile/student_profile_bloc.dart';
import 'package:church_management_system/features/student/presentation/screens/student_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  bool _isAuthenticatedState(AuthState state) =>
      state is AuthAuthenticated || state is AuthDegraded;

  Widget _buildAuthenticatedApp(BuildContext context, AuthState state) {
    final user = state is AuthAuthenticated
        ? state.user
        : (state as AuthDegraded).user;

    Widget homeWidget;
    List<BlocProvider> featureProviders = [];

    switch (user.role) {
      case UserRole.servant:
      case UserRole.admin:
        featureProviders = [
          BlocProvider<StudentDataBloc>(
            create: (context) => StudentDataBloc(
              studentRepository: getIt<IStudentRepository>(),
              getStudentsList: getIt<GetStudentsListUseCase>(),
              canMutateStudent: getIt<CanMutateStudentUseCase>(),
              provisionUseCase: getIt<ProvisionStudentWithAuthUseCase>(),
            ),
          ),
          BlocProvider<ServantDataBloc>(
            create: (context) => ServantDataBloc(
              repository: getIt<IServantRepository>(),
              provisionUseCase: getIt<ProvisionServantWithAuthUseCase>(),
            ),
          ),
        ];

        homeWidget = user.role == UserRole.admin
            ? (state is AuthAuthenticated
                  ? const AdminDashboardScreen()
                  : _AdminRefreshRequiredScreen(
                      message: (state as AuthDegraded).message,
                    ))
            : ServantDashboardScreen(user: user);
        break;
      case UserRole.student:
        featureProviders = [
          BlocProvider<StudentProfileBloc>(
            create: (context) => StudentProfileBloc(
              studentRepository: getIt<IStudentRepository>(),
            ),
          ),
        ];
        homeWidget = StudentProfileScreen(user: user);
        break;
      default:
        homeWidget = const Scaffold(body: Center(child: Text('غير مصرح')));
    }

    return MultiBlocProvider(
      providers: featureProviders,
      child: MaterialApp(
        title: 'اعداد خدام',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        onGenerateRoute: getIt<AppRouter>().onGenerateRoute,
        home: homeWidget,
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

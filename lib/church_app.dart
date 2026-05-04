import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/core/routing/app_router.dart';
import 'package:church_management_system/core/theme/app_theme.dart';
import 'package:church_management_system/features/auth/domain/repos/auth_repository.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/role_user_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChurchApp extends StatelessWidget {
  const ChurchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              AuthBloc(authService: getIt<AuthRepository>())
                ..add(const AuthEventCheckStatus()),
        ),
      ],
      child: MaterialApp(
        title: 'اعداد خدام',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        onGenerateRoute: getIt<AppRouter>().onGenerateRoute,
        home: const RoleUserRoute(),
      ),
    );
  }
}

import 'package:church_managment_system/core/di/injection_container.dart';
import 'package:church_managment_system/core/theme/app_theme.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_managment_system/features/home/presentation/pages/home_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepository: sl())..add(AuthCheckStatus()),
        ),
      ],
      child: MaterialApp(
        title: 'Church Management System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeWrapper(),
      ),
    );
  }
}

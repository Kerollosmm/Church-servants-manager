import 'package:csms/Features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/app_root.dart';
import 'package:csms/core/routing/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  runApp(ChurchApp(appRoutes: AppRouter()));
}

class ChurchApp extends StatelessWidget {
  const ChurchApp({super.key, required this.appRoutes});

  final AppRouter appRoutes;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc()..add(const AuthEventCheckStatus()),
      child: MaterialApp(
        title: 'CSMS',
        debugShowCheckedModeBanner: false,
        onGenerateRoute: appRoutes.onGenerateRoute,
        home: const AppRoot(),
      ),
    );
  }
}

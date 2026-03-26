import 'package:church_management_system/core/routing/app_router.dart';
import 'package:church_management_system/core/di/injection.dart';
import 'package:flutter/material.dart';

class ChurchApp extends StatelessWidget {
  const ChurchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اعداد خدام',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      onGenerateRoute: getIt<AppRouter>().onGenerateRoute,
    );
  }
}

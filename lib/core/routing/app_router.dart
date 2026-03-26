import 'package:flutter/material.dart';

class AppRouter {
  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(body: Center(child: Text('Not Found'))),
      settings: settings,
    );
  }
}

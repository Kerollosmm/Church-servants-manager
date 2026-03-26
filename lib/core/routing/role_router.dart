import 'package:church_management_system/core/constants/enums.dart';
import 'package:flutter/material.dart';
import 'package:provider/single_child_widget.dart';

class RoleRouter {
  const RoleRouter._();

  static List<SingleChildWidget> listeners() {
    return [];
  }

  static Widget resolve(UserRole role, dynamic state) {
    return const SizedBox.shrink();
  }
}

class AdminRefreshRequiredScreen extends StatelessWidget {
  const AdminRefreshRequiredScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تم إيقاف صلاحيات المسؤول مؤقتا')),
      body: Center(child: Text(message)),
    );
  }
}

class ArchivedAccountScreen extends StatelessWidget {
  const ArchivedAccountScreen({super.key, required this.message, this.email});

  final String message;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تم إيقاف الحساب')),
      body: Center(child: Text(message)),
    );
  }
}

import 'package:csms/Features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/core/models/auth_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentHomeScreen extends StatelessWidget {
  final AuthUser user;

  const StudentHomeScreen({super.key, required this.user});

  Future<void> _onRefresh(BuildContext context) async {
    context.read<AuthBloc>().add(const AuthEventRefreshUser());
    // Wait a bit for the state to update
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text('Student Home'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const AuthEventSignOut());
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, size: 80, color: Colors.orange.shade700),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome Student',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.orange.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _infoRow('Email', user.email),
                          _infoRow('Role', user.role.name.toUpperCase()),
                          _infoRow('Grade', user.grade ?? 'N/A'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Pull down to refresh your role',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}

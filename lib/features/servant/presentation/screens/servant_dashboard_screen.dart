import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/models/auth_user.dart';
import 'package:church_managment_system/core/routing/app_router.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServantDashboardScreen extends StatelessWidget {
  final AuthUser user;
  static const double _appBarOffset = 100.0;

  const ServantDashboardScreen({super.key, required this.user});

  Future<void> _onRefresh(BuildContext context) async {
    final authBloc = context.read<AuthBloc>();
    // Wait for the next non-loading state
    final future = authBloc.stream.firstWhere((state) => state is! AuthLoading);
    authBloc.add(const AuthEventRefreshUser());
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.role == UserRole.admin;

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: _buildAppBar(context, isAdmin),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - _appBarOffset,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.church, size: 80, color: Colors.teal.shade700),
                  const SizedBox(height: 24),
                  Text(
                    isAdmin ? 'Welcome Admin' : 'Welcome Servant',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.name,
                    style: TextStyle(fontSize: 22, color: Colors.teal.shade600),
                  ),
                  const SizedBox(height: 32),
                  _UserStatsCard(user: user),
                  const SizedBox(height: 24),
                  // View Students button for admins and servants
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRouter.studentList);
                    },
                    icon: const Icon(Icons.people),
                    label: const Text('View Students'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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

  AppBar _buildAppBar(BuildContext context, bool isAdmin) {
    return AppBar(
      title: Text(isAdmin ? 'Admin Dashboard' : 'Servant Dashboard'),
      backgroundColor: Colors.teal,
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
    );
  }
}

class _UserStatsCard extends StatelessWidget {
  final AuthUser user;

  const _UserStatsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow('Email', user.email),
            _infoRow('Role', user.role.name.toUpperCase()),
          ],
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

import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/common/app_key_value_row.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key, required this.user});

  final AuthUser user;

  Future<void> _onRefresh(BuildContext context) {
    context.read<AuthBloc>().add(const AuthEventRefreshUser());
    return Future<void>.value();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('الصفحة الرئيسية للمخدوم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const AuthEventSignOut());
            },
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.12,
                      ),
                      foregroundColor: AppColors.primary,
                      child: const Icon(Icons.school_outlined),
                    ),
                    AppSpacing.gapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          AppSpacing.gapXs,
                          Text(
                            'أهلا بك في مساحة المخدوم الخاصة بك',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapLg,
            Card(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    AppKeyValueRow(
                      label: 'البريد الإلكتروني',
                      value: user.email,
                      dense: true,
                      valueTextAlign: TextAlign.end,
                    ),
                    AppKeyValueRow(
                      label: 'الدور',
                      value: user.role.name,
                      dense: true,
                      valueTextAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapLg,
            const AppInfoBanner(
              icon: Icons.refresh,
              message: 'اسحب لأسفل لتحديث بياناتك الحالية.',
            ),
          ],
        ),
      ),
    );
  }
}

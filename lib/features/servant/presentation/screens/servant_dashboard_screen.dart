import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/common/app_key_value_row.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_dashboard_cubit.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServantDashboardScreen extends StatelessWidget {
  const ServantDashboardScreen({super.key, required this.user});

  final AuthUser user;

  Future<void> _onRefresh(BuildContext context) async {
    final authBloc = context.read<AuthBloc>();
    final future = authBloc.stream
        .firstWhere((state) => state is! AuthLoading)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => const AuthError('Refresh timed out'),
        );
    authBloc.add(const AuthEventRefreshUser());
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الخادم'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
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
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEAF4FF), Color(0xFFF7FAFC)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: AppRadius.lgRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: AppRadius.mdRadius,
                        ),
                        child: const Icon(
                          Icons.church_outlined,
                          size: 30,
                          color: AppColors.primary,
                        ),
                      ),
                      AppSpacing.gapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'أهلا بك',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            AppSpacing.gapXs,
                            Text(
                              user.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapMd,
                  Text(
                    'راجع فريقك الحالي، وتابع التعيينات، واسحب للتحديث عند تغيير الصلاحيات.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapLg,
            _UserStatsCard(user: user),
            AppSpacing.gapLg,
            FilledButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, studentList);
              },
              icon: const Icon(Icons.groups_2_outlined),
              label: const Text('إدارة مخدومي الفريق'),
            ),
            AppSpacing.gapSm,
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, attendanceHistory);
              },
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('تسجيل الحضور'),
            ),
            AppSpacing.gapSm,
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

class _UserStatsCard extends StatefulWidget {
  const _UserStatsCard({required this.user});

  final AuthUser user;

  @override
  State<_UserStatsCard> createState() => _UserStatsCardState();
}

class _UserStatsCardState extends State<_UserStatsCard> {
  late ServantDashboardCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = ServantDashboardCubit(
      teamRepository: context.read<TeamRepository>(),
    )..loadAssignedTeamNames(widget.user.effectiveAssignedTeamIds);
  }

  @override
  void didUpdateWidget(covariant _UserStatsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.effectiveAssignedTeamIds.join() !=
        widget.user.effectiveAssignedTeamIds.join()) {
      _cubit.loadAssignedTeamNames(widget.user.effectiveAssignedTeamIds);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = widget.user.role == UserRole.servant
        ? 'خادم'
        : widget.user.role.name;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
      child: BlocProvider.value(
        value: _cubit,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ملخص الحساب',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              AppSpacing.gapMd,
              AppKeyValueRow(
                label: 'البريد الإلكتروني',
                value: widget.user.email,
              ),
              AppKeyValueRow(label: 'الدور', value: roleLabel),
              if (widget.user.role == UserRole.servant) ...[
                AppKeyValueRow(
                  label: 'المجموعة',
                  value: widget.user.groupId ?? '--',
                ),
                _AssignedTeamsRow(user: widget.user),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignedTeamsRow extends StatelessWidget {
  const _AssignedTeamsRow({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final assignedTeamIds = user.effectiveAssignedTeamIds;
    if (assignedTeamIds.isEmpty) {
      return const AppKeyValueRow(label: 'الفريق المكلف به', value: 'غير محدد');
    }

    return BlocBuilder<ServantDashboardCubit, ServantDashboardState>(
      builder: (context, state) {
        final teamNames = state.isLoading
            ? 'جار التحميل...'
            : state.teamNames.isNotEmpty
            ? state.teamNames.join('، ')
            : (state.errorMessage ?? 'تعذر تحديد الفريق');
        final label = assignedTeamIds.length > 1
            ? 'الفرق المكلف بها'
            : 'الفريق المكلف به';
        return AppKeyValueRow(label: label, value: teamNames);
      },
    );
  }
}

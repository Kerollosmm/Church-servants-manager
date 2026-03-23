import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/atoms/app_text_button.dart';
import 'package:church_management_system/core/widgets/molecules/app_section_card.dart';
import 'package:church_management_system/core/widgets/molecules/app_stat_card.dart';
import 'package:church_management_system/core/widgets/organisms/app_header.dart';
import 'package:church_management_system/core/widgets/organisms/app_screen_shell.dart';
import 'package:church_management_system/features/admin/presentation/bloc/admin_dashboard_cubit.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, this.cubit});

  final AdminDashboardCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<AdminDashboardCubit>.value(
        value: cubit!,
        child: const _AdminDashboardView(),
      );
    }
    return BlocProvider<AdminDashboardCubit>(
      create: (context) => AdminDashboardCubit(
        studentRepository: context.read<StudentDataRepository>(),
        servantRepository: context.read<ServantDataRepository>(),
        teamRepository: context.read<TeamRepository>(),
        attendanceRepository: context.read<IAttendanceRepository>(),
      ),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

  @override
  Widget build(BuildContext context) {
    final String adminName = switch (context.watch<AuthBloc>().state) {
      AuthAuthenticated(:final user) => user.name,
      AuthDegraded(:final user) => user.name,
      _ => 'الأدمن',
    };

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppScreenShell(
        padding: const EdgeInsets.all(AppSpacing.spacingM),
        body: BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    const AppHeader(
                      title: 'لوحة التحكم',
                      subtitle: 'لوحة تحكم نظام إدارة الكنيسة',
                      showLogo: true,
                    ),
                    AppSpacing.gapSm,
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: AppTextButton(
                        label: 'تسجيل الخروج',
                        onPressed: () {
                          context.read<AuthBloc>().add(
                            const AuthEventSignOut(),
                          );
                        },
                      ),
                    ),
                    AppSpacing.gapSm,
                    _WelcomeStrip(adminName: adminName),
                    AppSpacing.gapLg,
                    if (state.isLoading) ...[
                      const LinearProgressIndicator(minHeight: 3),
                      AppSpacing.gapMd,
                    ],
                    _StatsRow(state: state),
                    AppSpacing.gapLg,
                    _RecentSessionsList(sessions: state.recentSessions),
                    AppSpacing.gapLg,
                    const _QuickActionsGrid(),
                    if (state.errorMessage != null) ...[
                      AppSpacing.gapLg,
                      Text(
                        state.errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    AppSpacing.gapLg,
                  ]),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WelcomeStrip extends StatelessWidget {
  const _WelcomeStrip({required this.adminName});

  final String adminName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.spacingM),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Text('مرحباً، $adminName', style: theme.textTheme.titleLarge),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.state});

  final AdminDashboardState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppStatCard(
            icon: Icons.groups_2_outlined,
            value: state.totalStudents.toString(),
            label: 'المخدومون',
          ),
        ),
        AppSpacing.gapSm,
        Expanded(
          child: AppStatCard(
            icon: Icons.volunteer_activism_outlined,
            value: state.totalServants.toString(),
            label: 'الخدام',
          ),
        ),
        AppSpacing.gapSm,
        Expanded(
          child: AppStatCard(
            icon: Icons.event_note_outlined,
            value: state.sessionsThisMonth.toString(),
            label: 'جلسات الشهر',
          ),
        ),
      ],
    );
  }
}

class _RecentSessionsList extends StatelessWidget {
  const _RecentSessionsList({required this.sessions});

  final List<AttendanceSession> sessions;

  @override
  Widget build(BuildContext context) {
    final items = sessions.take(3).toList(growable: false);

    return AppSectionCard(
      headerTitle: 'آخر الجلسات',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (items.isEmpty)
            Text(
              'لا توجد جلسات حديثة حتى الآن.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: AppSpacing.spacingL),
              itemBuilder: (context, index) =>
                  _RecentSessionTile(session: items[index]),
            ),
          AppSpacing.gapSm,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppTextButton(
              label: 'عرض الكل',
              onPressed: () => Navigator.pushNamed(context, attendanceHistory),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSessionTile extends StatelessWidget {
  const _RecentSessionTile({required this.session});

  final AttendanceSession session;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final title = session.title?.trim().isNotEmpty == true
        ? session.title!.trim()
        : 'جلسة حضور';
    final subtitle = <String>[
      session.teamNameSnapshot?.trim() ?? '',
      localizations.formatMediumDate(session.startsAt),
    ].where((value) => value.isNotEmpty).join(' - ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.event_available_outlined,
        color: AppColors.primary,
      ),
      title: Text(title),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    const actions = <_QuickActionItem>[
      _QuickActionItem(
        label: 'الطلاب',
        icon: Icons.groups_outlined,
        route: studentList,
      ),
      _QuickActionItem(
        label: 'الخدام',
        icon: Icons.supervisor_account_outlined,
        route: servantList,
      ),
      _QuickActionItem(
        label: 'الحضور',
        icon: Icons.fact_check_outlined,
        route: attendanceHistory,
      ),
      _QuickActionItem(
        label: 'الإعدادات',
        icon: Icons.settings_outlined,
        route: teamManagement,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.spacingM,
        mainAxisSpacing: AppSpacing.spacingM,
        childAspectRatio: 1.35,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          onTap: () => Navigator.pushNamed(context, action.route),
          child: AppSectionCard(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: AppSpacing.spacingXS),
                  Icon(action.icon, color: AppColors.primary, size: 28),
                  AppSpacing.gapSm,
                  Text(
                    action.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionItem {
  const _QuickActionItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

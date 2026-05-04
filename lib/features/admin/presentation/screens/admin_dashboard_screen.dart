import 'package:church_management_system/core/constants/routes.dart' as routes;
import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/features/admin/presentation/bloc/dashboard/admin_dashboard_bloc.dart';
import 'package:church_management_system/features/admin/presentation/bloc/dashboard/admin_dashboard_event.dart';
import 'package:church_management_system/features/admin/presentation/bloc/dashboard/admin_dashboard_state.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<AdminDashboardBloc>()..add(const LoadDashboardData()),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            RepaintBoundary(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.8, -0.6),
                    radius: 1.5,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.08),
                      AppColors.background,
                    ],
                    stops: const [0.0, 0.6],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
                builder: (context, state) {
                  if (state is AdminDashboardLoading ||
                      state is AdminDashboardInitial) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is AdminDashboardError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'حدث خطأ أثناء تحميل البيانات:\n${state.message}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.error),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context.read<AdminDashboardBloc>().add(
                                  const LoadDashboardData(),
                                );
                              },
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (state is AdminDashboardLoaded) {
                    return CustomScrollView(
                      slivers: [
                        _buildHeader(context),
                        _buildWelcomeSection(context),
                        _buildStatGrid(context, state.kpiData),
                        _buildQuickActions(context),
                        _buildRecentActivity(context, state.recentActivity),
                        const SliverPadding(
                          padding: EdgeInsets.only(bottom: 100),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildHeader(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 72,
      leading: Padding(
        padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Image.asset(
            'assets/images/logo_elkarooz.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.church, color: AppColors.primary),
          ),
        ),
      ),
      title: const Text(
        'لوحة التحكم',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFF334155)),
          onPressed: () {
            context.read<AuthBloc>().add(const AuthEventSignOut());
          },
          tooltip: 'تسجيل الخروج',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: AppColors.primary.withValues(alpha: 0.1),
          height: 1,
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final theme = Theme.of(context);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أهلاً بك، الأدمن',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'لوحة تحكم نظام إدارة الكنيسة',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context, DashboardKpiData data) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.15,
        ),
        delegate: SliverChildListDelegate([
          _StatCard(
            title: 'إجمالي الطلاب',
            value: data.totalStudents.toString(),
            trend: '5%+',
            trendIcon: Icons.trending_up,
            trendColor: AppColors.success,
            icon: Icons.groups,
            onTap: () => Navigator.pushNamed(context, routes.studentList),
          ),
          _StatCard(
            title: 'الخدام',
            value: data.totalServants.toString(),
            trend: '2%+',
            trendIcon: Icons.trending_up,
            trendColor: AppColors.success,
            icon: Icons.volunteer_activism,
            onTap: () => Navigator.pushNamed(context, routes.servantList),
          ),
          _StatCard(
            title: 'الفرق',
            value: data.totalTeams.toString(),
            trend: '0%',
            trendColor: const Color(0xFF94A3B8),
            icon: Icons.diversity_3,
            onTap: () => Navigator.pushNamed(context, routes.teamManagement),
          ),
          _StatCard(
            title: 'معدل الحضور',
            value: '${data.attendanceRate.toInt()}%',
            trend: '8%+',
            trendIcon: Icons.trending_up,
            trendColor: AppColors.success,
            icon: Icons.fact_check,
            onTap: () => Navigator.pushNamed(context, routes.attendanceHistory),
          ),
        ]),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إجراءات سريعة',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    title: 'إضافة طالب',
                    icon: Icons.person_add,
                    isPrimary: true,
                    onPressed: () {
                      final authState = context.read<AuthBloc>().state;
                      if (authState is AuthAuthenticated) {
                        Navigator.pushNamed(
                          context,
                          routes.studentEdit,
                          arguments: StudentEditArgs(actor: authState.user),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    title: 'إنشاء فريق',
                    icon: Icons.group_add,
                    isPrimary: false,
                    onPressed: () {
                      Navigator.pushNamed(context, routes.teamManagement);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    title: 'بدء الحضور',
                    icon: Icons.calendar_today,
                    isPrimary: false,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        routes.attendanceSessionCreate,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(
    BuildContext context,
    List<ActivityLog> activities,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'النشاط الأخير',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text(
                  'عرض الكل',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('لا يوجد نشاط أخير', textAlign: TextAlign.center),
            )
          else
            ...activities.map((activity) => _ActivityItem(activity: activity)),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final IconData? trendIcon;
  final Color trendColor;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.trend,
    this.trendIcon,
    required this.trendColor,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.05)),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 24),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        trend,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: trendColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (trendIcon != null) ...[
                        const SizedBox(width: 2),
                        Icon(trendIcon, size: 14, color: trendColor),
                      ],
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Flexible(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        value,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = isPrimary ? AppColors.primary : Colors.white;
    final iconBgColor = isPrimary
        ? Colors.white.withValues(alpha: 0.2)
        : AppColors.primary.withValues(alpha: 0.1);
    final textColor = isPrimary ? Colors.white : const Color(0xFF334155);
    final iconColor = isPrimary ? Colors.white : AppColors.primary;
    final borderColor = isPrimary
        ? Colors.transparent
        : AppColors.primary.withValues(alpha: 0.1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final ActivityLog activity;

  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData iconData;
    Color color;
    Color bgColor;

    switch (activity.type) {
      case 'person':
        iconData = Icons.person;
        color = const Color(0xFF2563EB); // blue-600
        bgColor = const Color(0xFFDBEAFE); // blue-100
        break;
      case 'event':
        iconData = Icons.event;
        color = const Color(0xFFD97706); // amber-600
        bgColor = const Color(0xFFFEF3C7); // amber-100
        break;
      case 'assignment':
        iconData = Icons.assignment_turned_in;
        color = const Color(0xFF059669); // emerald-600
        bgColor = const Color(0xFFD1FAE5); // emerald-100
        break;
      default:
        iconData = Icons.notifications;
        color = AppColors.primary;
        bgColor = AppColors.primary.withValues(alpha: 0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activity.subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                activity.time,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

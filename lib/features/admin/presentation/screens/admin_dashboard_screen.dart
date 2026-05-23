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

class AdminDashboardScreen extends StatefulWidget {
  final String teamId;

  const AdminDashboardScreen({
    super.key,
    this.teamId = 'default_team_id', // Placeholder for now
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminDashboardBloc>(
      create: (context) => getIt<AdminDashboardBloc>()..add(const LoadDashboardData()),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(context),
          body: Builder(
            builder: (context) => RefreshIndicator(
              onRefresh: () async {
                context.read<AdminDashboardBloc>().add(const LoadDashboardData());
                // Wait a short delay for UX or until state isn't loading if we wanted.
                // We'll just return immediately for simplicity since BLoC handles state.
                await Future.delayed(const Duration(milliseconds: 300));
              },
              child: Stack(
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
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        _buildWelcomeSection(context),
                        SliverToBoxAdapter(
                          child: BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
                            builder: (context, state) {
                              if (state is AdminDashboardLoading ||
                                  state is AdminDashboardInitial) {
                                return const Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              } else if (state is AdminDashboardError) {
                                return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        size: 48,
                                        color: AppColors.error,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'حدث خطأ أثناء تحميل البيانات:\n${state.message}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          context.read<AdminDashboardBloc>().add(const LoadDashboardData());
                                        },
                                        child: const Text('إعادة المحاولة'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else if (state is AdminDashboardLoaded) {
                              return _buildStatsContent(context, state);
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      _buildQuickActions(context),
                      const SliverPadding(
                        padding: EdgeInsets.only(bottom: 100),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
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

  Widget _buildStatsContent(BuildContext context, AdminDashboardLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إحصائيات الحضور (هذا الأسبوع)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.15,
            children: [
              _StatCard(
                title: 'إجمالي الجلسات\nهذا الأسبوع',
                value: state.kpiData.totalSessions.toString(),
                icon: Icons.event,
                trendColor: AppColors.success,
              ),
              _StatCard(
                title: 'إجمالي الحضور',
                value: '${state.kpiData.attendanceRate.toStringAsFixed(1)}%',
                icon: Icons.people,
                trendColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'آخر تحديث: ${_formatDate(DateTime.now())}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
        ],
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
                    title: 'الطلاب',
                    icon: Icons.people_alt,
                    isPrimary: true,
                    onPressed: () {
                      Navigator.pushNamed(context, routes.studentList);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    title: 'الخدام',
                    icon: Icons.badge,
                    isPrimary: false,
                    onPressed: () {
                      Navigator.pushNamed(context, routes.servantList);
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    title: 'إضافة طالب',
                    icon: Icons.person_add,
                    isPrimary: false,
                    onPressed: () {
                      final authState = context.read<AuthBloc>().state;
                      if (authState is AuthAuthenticated) {
                        Navigator.pushNamed(
                          context,
                          routes.studentEdit,
                          arguments: StudentEditArgs(actor: authState.user),
                        );
                      } else if (authState is AuthDegraded) {
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color trendColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.trendColor,
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
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
                      maxLines: 2,
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

import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/app_empty_state.dart';
import 'package:church_management_system/core/widgets/atoms/app_primary_button.dart';
import 'package:church_management_system/core/widgets/atoms/app_text_button.dart';
import 'package:church_management_system/core/widgets/molecules/app_person_list_tile.dart';
import 'package:church_management_system/core/widgets/molecules/app_section_card.dart';
import 'package:church_management_system/core/widgets/molecules/app_stat_card.dart';
import 'package:church_management_system/core/widgets/organisms/app_header.dart';
import 'package:church_management_system/core/widgets/organisms/app_screen_shell.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_dashboard_cubit.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServantDashboardScreen extends StatelessWidget {
  const ServantDashboardScreen({super.key, required this.user, this.cubit});

  final AuthUser user;
  final ServantDashboardCubit? cubit;

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
    if (cubit != null) {
      return BlocProvider<ServantDashboardCubit>.value(
        value: cubit!,
        child: _ServantDashboardView(user: user, onRefresh: _onRefresh),
      );
    }

    return BlocProvider<ServantDashboardCubit>(
      create: (context) => ServantDashboardCubit(
        teamRepository: context.read<TeamRepository>(),
        studentRepository: context.read<StudentDataRepository>(),
        attendanceRepository: context.read<IAttendanceRepository>(),
      )..load(user.effectiveAssignedTeamIds),
      child: _ServantDashboardView(user: user, onRefresh: _onRefresh),
    );
  }
}

class _ServantDashboardView extends StatelessWidget {
  const _ServantDashboardView({required this.user, required this.onRefresh});

  final AuthUser user;
  final Future<void> Function(BuildContext context) onRefresh;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RefreshIndicator(
        onRefresh: () => onRefresh(context),
        child: AppScreenShell(
          padding: const EdgeInsets.all(AppSpacing.spacingM),
          body: BlocBuilder<ServantDashboardCubit, ServantDashboardState>(
            builder: (context, state) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      AppHeader(
                        title: user.name,
                        subtitle: 'خادم',
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
                      if (state.isLoading) ...[
                        const LinearProgressIndicator(minHeight: 3),
                        AppSpacing.gapMd,
                      ],
                      _MyStudentsSummary(state: state),
                      AppSpacing.gapLg,
                      _UpcomingSessions(sessions: state.upcomingSessions),
                      AppSpacing.gapLg,
                      _MyStudentsMiniList(students: state.assignedStudents),
                      AppSpacing.gapLg,
                      const _AttendanceCTA(),
                      if (state.errorMessage != null) ...[
                        AppSpacing.gapMd,
                        Text(
                          state.errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
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
      ),
    );
  }
}

class _MyStudentsSummary extends StatelessWidget {
  const _MyStudentsSummary({required this.state});

  final ServantDashboardState state;

  @override
  Widget build(BuildContext context) {
    final attendanceValue = state.weeklyAttendanceRate == null
        ? '--'
        : '${state.weeklyAttendanceRate!.round()}%';

    return AppSectionCard(
      headerTitle: 'ملخص خدمتي',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.currentTeamName != null &&
              state.currentTeamName!.isNotEmpty) ...[
            Text(
              'الفريق الحالي: ${state.currentTeamName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            AppSpacing.gapMd,
          ],
          AppStatCard(
            icon: Icons.groups_2_outlined,
            value: '${state.assignedStudents.length} - $attendanceValue',
            label: 'عدد الطلاب - نسبة الحضور هذا الأسبوع',
          ),
        ],
      ),
    );
  }
}

class _UpcomingSessions extends StatelessWidget {
  const _UpcomingSessions({required this.sessions});

  final List<AttendanceSession> sessions;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      headerTitle: 'الجلسات القادمة',
      child: sessions.isEmpty
          ? const AppEmptyState(
              title: 'لا توجد جلسات قادمة',
              subtitle: 'سيظهر هنا أول اجتماع قادم للفريق.',
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: AppSpacing.spacingL),
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _UpcomingSessionTile(session: session);
              },
            ),
    );
  }
}

class _UpcomingSessionTile extends StatelessWidget {
  const _UpcomingSessionTile({required this.session});

  final AttendanceSession session;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final title = session.title?.trim().isNotEmpty == true
        ? session.title!.trim()
        : 'جلسة خدمة';
    final subtitle = <String>[
      localizations.formatMediumDate(session.startsAt),
      session.teamNameSnapshot?.trim() ?? '',
    ].where((value) => value.isNotEmpty).join(' - ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_note_outlined),
      title: Text(title),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
    );
  }
}

class _MyStudentsMiniList extends StatelessWidget {
  const _MyStudentsMiniList({required this.students});

  final List<StudentModel> students;

  @override
  Widget build(BuildContext context) {
    final visibleStudents = students.take(5).toList(growable: false);

    return AppSectionCard(
      headerTitle: 'طلابي',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (visibleStudents.isEmpty)
            const AppEmptyState(
              title: 'لا يوجد طلاب بعد',
              subtitle: 'أضف طلاباً إلى فريقك ليظهروا هنا.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleStudents.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final student = visibleStudents[index];
                final subtitle = student.teamName.trim().isEmpty
                    ? 'بدون فريق'
                    : student.teamName.trim();
                return AppPersonListTile(
                  name: student.name,
                  subtitle: subtitle,
                  imageUrl: student.imageUrl,
                );
              },
            ),
          AppSpacing.gapSm,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppTextButton(
              label: 'عرض الكل',
              onPressed: () => Navigator.pushNamed(context, studentList),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCTA extends StatelessWidget {
  const _AttendanceCTA();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppPrimaryButton(
        label: 'تسجيل حضور',
        onPressed: () => Navigator.pushNamed(context, attendanceSessionCreate),
      ),
    );
  }
}

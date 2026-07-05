import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/widgets/sync_status_banner.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_enums.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance/attendance_bloc.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TakeAttendanceScreen extends StatelessWidget {
  final String teamId;
  final String sessionId;
  final String sessionTitle;

  const TakeAttendanceScreen({
    super.key,
    required this.teamId,
    required this.sessionId,
    required this.sessionTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(sessionTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AttendanceBloc>().add(
                LoadSessionRoster(teamId: teamId, sessionId: sessionId),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Global Sync Status Banner directly under the AppBar
          const SyncStatusBanner(),

          Expanded(
            child: BlocBuilder<AttendanceBloc, AttendanceState>(
              buildWhen: (previous, current) {
                // Rebuild list only if state type changes, or roster list structure changes
                if (previous.runtimeType != current.runtimeType) return true;
                if (previous is AttendanceSessionActive &&
                    current is AttendanceSessionActive) {
                  if (previous.roster.length != current.roster.length) {
                    return true;
                  }
                  for (int i = 0; i < previous.roster.length; i++) {
                    if (previous.roster[i].studentId !=
                        current.roster[i].studentId) {
                      return true;
                    }
                  }
                  return false;
                }
                return true;
              },
              builder: (context, state) {
                if (state is AttendanceLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AttendanceError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        state.message,
                        style: const TextStyle(color: AppColors.error, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (state is AttendanceSessionActive) {
                  final roster = state.roster;

                  if (roster.isEmpty) {
                    return const Center(
                      child: Text('لا يوجد مخدومين في هذا الفريق.'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: roster.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = roster[index];

                      return _RosterItemCard(
                        studentId: item.studentId,
                        teamId: teamId,
                        sessionId: sessionId,
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RosterItemCard extends StatelessWidget {
  final String studentId;
  final String teamId;
  final String sessionId;

  const _RosterItemCard({
    required this.studentId,
    required this.teamId,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AttendanceBloc, AttendanceState, AttendanceRosterItem?>(
      selector: (state) {
        if (state is! AttendanceSessionActive) return null;
        try {
          return state.roster.firstWhere((item) => item.studentId == studentId);
        } catch (_) {
          return null;
        }
      },
      builder: (context, item) {
        if (item == null) return const SizedBox.shrink();

        final isPresent = item.manualStatus == AttendanceMarkStatus.present;
        final isAbsent = item.manualStatus == AttendanceMarkStatus.absent;

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isPresent
                  ? AppColors.success
                  : isAbsent
                  ? AppColors.error
                  : AppColors.outline,
              width: (isPresent || isAbsent) ? 2 : 1,
            ),
          ),
          child: ListTile(
            title: Text(
              item.studentName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: item.isMarked
                ? Text(
                    'تم تسجيله بواسطة: ${item.markedByName}',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  )
                : const Text(
                    'لم يتم التسجيل بعد',
                    style: TextStyle(fontSize: 12),
                  ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Present Button
                IconButton(
                  icon: Icon(
                    Icons.check_circle,
                    color: isPresent ? AppColors.success : AppColors.outline,
                    size: 32,
                  ),
                  onPressed: () {
                    final authState = context.read<AuthBloc>().state;
                    if (authState is AuthAuthenticated) {
                      context.read<AttendanceBloc>().add(
                        ToggleAttendance(
                          studentId: item.studentId,
                          newStatus: AttendanceMarkStatus.present,
                          markedBy: authState.user,
                        ),
                      );
                    }
                  },
                ),
                // Absent Button
                IconButton(
                  icon: Icon(
                    Icons.cancel,
                    color: isAbsent ? AppColors.error : AppColors.outline,
                    size: 32,
                  ),
                  onPressed: () {
                    final authState = context.read<AuthBloc>().state;
                    if (authState is AuthAuthenticated) {
                      context.read<AttendanceBloc>().add(
                        ToggleAttendance(
                          studentId: item.studentId,
                          newStatus: AttendanceMarkStatus.absent,
                          markedBy: authState.user,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

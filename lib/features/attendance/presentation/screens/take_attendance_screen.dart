import 'package:church_management_system/core/widgets/sync_status_banner.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
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
                        style: const TextStyle(color: Colors.red, fontSize: 16),
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
                      final isPresent =
                          item.manualStatus == AttendanceMarkStatus.present;

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isPresent
                                ? Colors.green.shade300
                                : Colors.grey.shade300,
                            width: isPresent ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            item.studentName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: item.isMarked
                              ? Text(
                                  'تم تسجيله بواسطة: ${item.markedByName}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
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
                                  color: isPresent
                                      ? Colors.green
                                      : Colors.grey.shade400,
                                  size: 32,
                                ),
                                onPressed: () {
                                  final authState = context
                                      .read<AuthBloc>()
                                      .state;
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
                                  color:
                                      item.manualStatus ==
                                          AttendanceMarkStatus.absent
                                      ? Colors.red
                                      : Colors.grey.shade400,
                                  size: 32,
                                ),
                                onPressed: () {
                                  final authState = context
                                      .read<AuthBloc>()
                                      .state;
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

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

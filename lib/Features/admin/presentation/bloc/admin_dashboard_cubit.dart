import 'dart:async';

import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

class AdminDashboardState extends Equatable {
  const AdminDashboardState({
    this.isLoading = false,
    this.totalStudents = 0,
    this.totalServants = 0,
    this.sessionsThisMonth = 0,
    this.recentSessions = const <AttendanceSession>[],
    this.errorMessage,
  });

  final bool isLoading;
  final int totalStudents;
  final int totalServants;
  final int sessionsThisMonth;
  final List<AttendanceSession> recentSessions;
  final String? errorMessage;

  AdminDashboardState copyWith({
    bool? isLoading,
    int? totalStudents,
    int? totalServants,
    int? sessionsThisMonth,
    List<AttendanceSession>? recentSessions,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AdminDashboardState(
      isLoading: isLoading ?? this.isLoading,
      totalStudents: totalStudents ?? this.totalStudents,
      totalServants: totalServants ?? this.totalServants,
      sessionsThisMonth: sessionsThisMonth ?? this.sessionsThisMonth,
      recentSessions: recentSessions ?? this.recentSessions,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    totalStudents,
    totalServants,
    sessionsThisMonth,
    recentSessions,
    errorMessage,
  ];
}

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit({
    required StudentDataRepository studentRepository,
    required ServantDataRepository servantRepository,
    required TeamRepository teamRepository,
    required IAttendanceRepository attendanceRepository,
  }) : _studentRepository = studentRepository,
       _servantRepository = servantRepository,
       _teamRepository = teamRepository,
       _attendanceRepository = attendanceRepository,
       super(const AdminDashboardState(isLoading: true)) {
    _bindStreams();
  }

  AdminDashboardCubit.seeded(super.initialState)
    : _studentRepository = null,
      _servantRepository = null,
      _teamRepository = null,
      _attendanceRepository = null,
      super();

  final StudentDataRepository? _studentRepository;
  final ServantDataRepository? _servantRepository;
  final TeamRepository? _teamRepository;
  final IAttendanceRepository? _attendanceRepository;

  StreamSubscription<AdminDashboardState>? _subscription;

  void pushState(AdminDashboardState nextState) => emit(nextState);

  void _bindStreams() {
    final studentRepository = _studentRepository;
    final servantRepository = _servantRepository;
    final teamRepository = _teamRepository;
    final attendanceRepository = _attendanceRepository;

    if (studentRepository == null ||
        servantRepository == null ||
        teamRepository == null ||
        attendanceRepository == null) {
      return;
    }

    _subscription =
        Rx.combineLatest3<
              List<StudentModel>,
              List<ServantModel>,
              _AdminAttendanceSummary,
              AdminDashboardState
            >(
              studentRepository.watchAllStudents(),
              servantRepository.getServantsStream(),
              _watchAttendanceSummary(teamRepository, attendanceRepository),
              (students, servants, attendance) => AdminDashboardState(
                totalStudents: students.length,
                totalServants: servants.length,
                sessionsThisMonth: attendance.sessionsThisMonth,
                recentSessions: attendance.recentSessions,
              ),
            )
            .listen(
              emit,
              onError: (Object error, StackTrace stackTrace) {
                if (kDebugMode) {
                  debugPrint(
                    'AdminDashboardCubit: failed to load dashboard '
                    '(${error.runtimeType})',
                  );
                  debugPrintStack(stackTrace: stackTrace);
                }
                emit(
                  state.copyWith(
                    isLoading: false,
                    errorMessage: 'تعذر تحميل بيانات لوحة التحكم حالياً.',
                  ),
                );
              },
            );
  }

  Stream<_AdminAttendanceSummary> _watchAttendanceSummary(
    TeamRepository teamRepository,
    IAttendanceRepository attendanceRepository,
  ) {
    return teamRepository.watchAllTeams().switchMap((List<TeamModel> teams) {
      if (teams.isEmpty) {
        return Stream.value(const _AdminAttendanceSummary());
      }

      final List<Stream<List<AttendanceSession>>> sessionStreams = teams
          .map((team) => attendanceRepository.watchSessionsForTeam(team.id))
          .toList(growable: false);

      return Rx.combineLatestList(sessionStreams).map((
        List<List<AttendanceSession>> groups,
      ) {
        final List<AttendanceSession> sessions =
            groups.expand((items) => items).toList(growable: false)
              ..sort((a, b) => b.startsAt.compareTo(a.startsAt));

        final DateTime now = DateTime.now();
        final int sessionsThisMonth = sessions.where((session) {
          return session.startsAt.year == now.year &&
              session.startsAt.month == now.month;
        }).length;

        return _AdminAttendanceSummary(
          sessionsThisMonth: sessionsThisMonth,
          recentSessions: sessions.take(3).toList(growable: false),
        );
      });
    });
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

class _AdminAttendanceSummary {
  const _AdminAttendanceSummary({
    this.sessionsThisMonth = 0,
    this.recentSessions = const <AttendanceSession>[],
  });

  final int sessionsThisMonth;
  final List<AttendanceSession> recentSessions;
}

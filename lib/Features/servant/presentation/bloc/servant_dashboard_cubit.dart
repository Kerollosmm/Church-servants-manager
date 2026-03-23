import 'dart:async';

import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

class ServantDashboardState extends Equatable {
  const ServantDashboardState({
    this.isLoading = false,
    this.teamNames = const <String>[],
    this.currentTeamName,
    this.assignedStudents = const <StudentModel>[],
    this.upcomingSessions = const <AttendanceSession>[],
    this.weeklyAttendanceRate,
    this.errorMessage,
  });

  final bool isLoading;
  final List<String> teamNames;
  final String? currentTeamName;
  final List<StudentModel> assignedStudents;
  final List<AttendanceSession> upcomingSessions;
  final double? weeklyAttendanceRate;
  final String? errorMessage;

  ServantDashboardState copyWith({
    bool? isLoading,
    List<String>? teamNames,
    String? currentTeamName,
    bool clearCurrentTeamName = false,
    List<StudentModel>? assignedStudents,
    List<AttendanceSession>? upcomingSessions,
    double? weeklyAttendanceRate,
    bool clearWeeklyAttendanceRate = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ServantDashboardState(
      isLoading: isLoading ?? this.isLoading,
      teamNames: teamNames ?? this.teamNames,
      currentTeamName: clearCurrentTeamName
          ? null
          : (currentTeamName ?? this.currentTeamName),
      assignedStudents: assignedStudents ?? this.assignedStudents,
      upcomingSessions: upcomingSessions ?? this.upcomingSessions,
      weeklyAttendanceRate: clearWeeklyAttendanceRate
          ? null
          : (weeklyAttendanceRate ?? this.weeklyAttendanceRate),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    teamNames,
    currentTeamName,
    assignedStudents,
    upcomingSessions,
    weeklyAttendanceRate,
    errorMessage,
  ];
}

class ServantDashboardCubit extends Cubit<ServantDashboardState> {
  ServantDashboardCubit({
    required TeamRepository teamRepository,
    required StudentDataRepository studentRepository,
    required IAttendanceRepository attendanceRepository,
    DateTime Function()? nowProvider,
  }) : _teamRepository = teamRepository,
       _studentRepository = studentRepository,
       _attendanceRepository = attendanceRepository,
       _nowProvider = nowProvider ?? DateTime.now,
       super(const ServantDashboardState());

  ServantDashboardCubit.seeded(super.initialState)
    : _teamRepository = null,
      _studentRepository = null,
      _attendanceRepository = null,
      _nowProvider = DateTime.now,
      super();

  final TeamRepository? _teamRepository;
  final StudentDataRepository? _studentRepository;
  final IAttendanceRepository? _attendanceRepository;
  final DateTime Function() _nowProvider;

  StreamSubscription<ServantDashboardState>? _subscription;

  void pushState(ServantDashboardState nextState) => emit(nextState);

  Future<void> loadAssignedTeamNames(List<String> assignedTeamIds) {
    return load(assignedTeamIds);
  }

  Future<void> load(List<String> assignedTeamIds) async {
    await _subscription?.cancel();

    final teamRepository = _teamRepository;
    final studentRepository = _studentRepository;
    final attendanceRepository = _attendanceRepository;

    final teamIds = assignedTeamIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (teamIds.isEmpty) {
      emit(
        const ServantDashboardState(
          teamNames: <String>[],
          assignedStudents: <StudentModel>[],
          upcomingSessions: <AttendanceSession>[],
        ),
      );
      return;
    }

    if (teamRepository == null ||
        studentRepository == null ||
        attendanceRepository == null) {
      return;
    }

    emit(state.copyWith(isLoading: true, clearErrorMessage: true));

    final Stream<List<String>> teamNamesStream = teamRepository
        .watchAllTeams()
        .map((List<TeamModel> teams) {
          final namesById = <String, String>{
            for (final team in teams) team.id: team.name.trim(),
          };
          return teamIds
              .map((teamId) => namesById[teamId])
              .whereType<String>()
              .where((name) => name.isNotEmpty)
              .toList(growable: false);
        });

    final Stream<List<StudentModel>> studentsStream = teamIds.length == 1
        ? studentRepository.watchStudentsByClass(teamIds.first)
        : studentRepository.watchStudentsByClasses(teamIds);

    final Stream<List<AttendanceSession>> upcomingSessionsStream =
        _watchUpcomingSessions(teamIds, attendanceRepository);

    _subscription =
        Rx.combineLatest3<
              List<String>,
              List<StudentModel>,
              List<AttendanceSession>,
              ServantDashboardState
            >(teamNamesStream, studentsStream, upcomingSessionsStream, (
              teamNames,
              students,
              upcomingSessions,
            ) {
              return state.copyWith(
                isLoading: false,
                teamNames: teamNames,
                currentTeamName: teamNames.isEmpty ? null : teamNames.first,
                assignedStudents: students,
                upcomingSessions: upcomingSessions,
                clearErrorMessage: true,
              );
            })
            .listen(
              emit,
              onError: (Object error, StackTrace stackTrace) {
                if (kDebugMode) {
                  debugPrint(
                    'ServantDashboardCubit: failed to load dashboard '
                    '(${error.runtimeType})',
                  );
                  debugPrintStack(stackTrace: stackTrace);
                }
                emit(
                  state.copyWith(
                    isLoading: false,
                    errorMessage: 'تعذر تحميل لوحة الخادم حالياً.',
                  ),
                );
              },
            );

    try {
      final attendanceRate = await _loadWeeklyAttendanceRate(
        teamIds,
        attendanceRepository,
      );
      emit(
        state.copyWith(
          isLoading: false,
          weeklyAttendanceRate: attendanceRate,
          clearErrorMessage: true,
        ),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'ServantDashboardCubit: failed to load attendance rate '
          '(${error.runtimeType})',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'تعذر حساب نسبة الحضور لهذا الأسبوع.',
        ),
      );
    }
  }

  Stream<List<AttendanceSession>> _watchUpcomingSessions(
    List<String> teamIds,
    IAttendanceRepository attendanceRepository,
  ) {
    final streams = teamIds
        .map((teamId) => attendanceRepository.watchSessionsForTeam(teamId))
        .toList(growable: false);

    if (streams.length == 1) {
      return streams.first.map(_sortUpcomingSessions);
    }

    return Rx.combineLatestList(streams).map((groups) {
      return _sortUpcomingSessions(groups.expand((items) => items).toList());
    });
  }

  List<AttendanceSession> _sortUpcomingSessions(
    List<AttendanceSession> sessions,
  ) {
    final now = _nowProvider();
    final upcoming =
        sessions
            .where((session) => !session.startsAt.isBefore(now))
            .toList(growable: false)
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return upcoming.take(2).toList(growable: false);
  }

  Future<double> _loadWeeklyAttendanceRate(
    List<String> teamIds,
    IAttendanceRepository attendanceRepository,
  ) async {
    final now = _nowProvider();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final range = DateTimeRange(start: weekStart, end: weekEnd);

    final stats = await Future.wait(
      teamIds.map(
        (teamId) => attendanceRepository.getTeamAttendanceStats(
          teamId: teamId,
          range: range,
        ),
      ),
    );

    final totalRosterEntries = stats.fold<int>(
      0,
      (sum, item) => sum + item.totalRosterEntries,
    );
    final attendedEntries = stats.fold<int>(
      0,
      (sum, item) => sum + item.attendedCount,
    );

    if (totalRosterEntries == 0) {
      return 0;
    }

    return (attendedEntries / totalRosterEntries * 100)
        .clamp(0, 100)
        .toDouble();
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

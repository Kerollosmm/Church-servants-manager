import 'dart:async';

import 'package:church_management_system/features/attendance/presentation/bloc/timer/attendance_session_timer_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// FIX [008]: Cubit that owns a Timer.periodic for the session countdown. (T016)
// Kept separate from AttendanceTakingCubit to avoid roster rebuilds every second.

/// Countdown timer cubit for an attendance session.
///
/// Starts a 1-second periodic timer when [start] is called. Emits a warning
/// state when ≤ 10 minutes remain. Stops automatically on expiry or [close].
class AttendanceSessionTimerCubit extends Cubit<AttendanceSessionTimerState> {
  AttendanceSessionTimerCubit()
    : super(
        const AttendanceSessionTimerState(
          remainingSeconds: 0,
          showWarning: false,
          isExpired: false,
        ),
      );

  static const int _warningThresholdSeconds = 600; // 10 minutes

  Timer? _timer;
  DateTime? _endsAt;

  /// Starts (or restarts) the countdown for a session that ends at [endsAt].
  void start(DateTime endsAt) {
    _endsAt = endsAt;
    _timer?.cancel();
    _tick(); // Emit immediately so the UI reflects state without waiting 1s.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_endsAt == null || isClosed) return;

    final remaining = _endsAt!.difference(DateTime.now()).inSeconds;
    final isExpired = remaining <= 0;
    final showWarning = remaining <= _warningThresholdSeconds;

    emit(
      AttendanceSessionTimerState(
        remainingSeconds: remaining,
        showWarning: showWarning,
        isExpired: isExpired,
      ),
    );

    if (isExpired) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    _timer = null;
    return super.close();
  }
}

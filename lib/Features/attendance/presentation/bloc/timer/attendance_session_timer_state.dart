import 'package:equatable/equatable.dart';

// FIX [008]: Timer state for the attendance session expiry countdown. (T015)

/// State emitted by [AttendanceSessionTimerCubit] every second when the
/// session is within 10 minutes of expiry, and once on expiry.
final class AttendanceSessionTimerState extends Equatable {
  const AttendanceSessionTimerState({
    required this.remainingSeconds,
    required this.showWarning,
    required this.isExpired,
  });

  /// Seconds remaining until the session ends. Can be negative after expiry.
  final int remainingSeconds;

  /// True when remaining time is ≤ 10 minutes (600 seconds) or already expired.
  final bool showWarning;

  /// True when the session has ended (remainingSeconds ≤ 0).
  final bool isExpired;

  /// Human-readable MM:SS string for the UI.
  String get formattedRemaining {
    if (isExpired) return '00:00';
    final clamped = remainingSeconds.clamp(0, double.maxFinite.toInt());
    final minutes = clamped ~/ 60;
    final seconds = clamped % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [remainingSeconds, showWarning, isExpired];
}

import 'package:hive/hive.dart';

part 'attendance_enums.g.dart';

@HiveType(typeId: 12)
enum AttendanceMarkStatus {
  @HiveField(0)
  present,
  @HiveField(1)
  late,
  @HiveField(2)
  absent,
}

enum AttendanceEffectiveStatus { present, late, absent, unmarked }

/// Session lifecycle status for real-time stream monitoring.
enum SessionStatus { open, closed, reopened }

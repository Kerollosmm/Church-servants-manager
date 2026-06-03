class AttendanceSession {
  final String id;
  final String teamId;
  final String? teamNameSnapshot;
  final String? title;
  final String dateKey;
  final DateTime startsAt;
  final DateTime endsAt;
  final int durationMinutes;
  final String createdByUserId;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isClosed;
  final List<String> studentIdsSnapshot;
  final Map<String, String> studentNameSnapshots;
  final int presentCount;
  final int lateCount;
  final int absentCount;

  const AttendanceSession({
    required this.id,
    required this.teamId,
    this.teamNameSnapshot,
    this.title,
    required this.dateKey,
    required this.startsAt,
    required this.endsAt,
    required this.durationMinutes,
    required this.createdByUserId,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.isClosed = false,
    this.studentIdsSnapshot = const <String>[],
    this.studentNameSnapshots = const <String, String>{},
    this.presentCount = 0,
    this.lateCount = 0,
    this.absentCount = 0,
  });

  bool isOpenAt(DateTime now) {
    return !isClosed &&
        !now.toUtc().isBefore(startsAt) &&
        now.toUtc().isBefore(endsAt);
  }

  bool isEffectivelyClosedAt(DateTime now) {
    return isClosed || !now.toUtc().isBefore(endsAt);
  }

  static String buildDateKey(DateTime date) {
    return date.toUtc().toIso8601String().substring(0, 10);
  }

  AttendanceSession copyWith({
    String? id,
    String? teamId,
    String? teamNameSnapshot,
    String? title,
    String? dateKey,
    DateTime? startsAt,
    DateTime? endsAt,
    int? durationMinutes,
    String? createdByUserId,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isClosed,
    List<String>? studentIdsSnapshot,
    Map<String, String>? studentNameSnapshots,
    int? presentCount,
    int? lateCount,
    int? absentCount,
  }) {
    return AttendanceSession(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      teamNameSnapshot: teamNameSnapshot ?? this.teamNameSnapshot,
      title: title ?? this.title,
      dateKey: dateKey ?? this.dateKey,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isClosed: isClosed ?? this.isClosed,
      studentIdsSnapshot: studentIdsSnapshot ?? this.studentIdsSnapshot,
      studentNameSnapshots: studentNameSnapshots ?? this.studentNameSnapshots,
      presentCount: presentCount ?? this.presentCount,
      lateCount: lateCount ?? this.lateCount,
      absentCount: absentCount ?? this.absentCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          teamId == other.teamId &&
          teamNameSnapshot == other.teamNameSnapshot &&
          title == other.title &&
          dateKey == other.dateKey &&
          startsAt == other.startsAt &&
          endsAt == other.endsAt &&
          durationMinutes == other.durationMinutes &&
          createdByUserId == other.createdByUserId &&
          createdByName == other.createdByName &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          isClosed == other.isClosed &&
          presentCount == other.presentCount &&
          lateCount == other.lateCount &&
          absentCount == other.absentCount;

  @override
  int get hashCode =>
      id.hashCode ^
      teamId.hashCode ^
      teamNameSnapshot.hashCode ^
      title.hashCode ^
      dateKey.hashCode ^
      startsAt.hashCode ^
      endsAt.hashCode ^
      durationMinutes.hashCode ^
      createdByUserId.hashCode ^
      createdByName.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      isClosed.hashCode ^
      presentCount.hashCode ^
      lateCount.hashCode ^
      absentCount.hashCode;
}

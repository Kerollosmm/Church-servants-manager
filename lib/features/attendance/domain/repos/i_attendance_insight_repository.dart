abstract class IAttendanceInsightRepository {
  /// US-01: Fetches AI-generated insights for a specific group.
  Future<AttendanceInsight> getGroupInsight({
    required String groupId,
    required String question,
  });

  /// US-03: Fetches personal encouragement for a student.
  Future<String?> getStudentEncouragement({required String studentId});

  /// US-02: Process natural language queries about attendance.
  Future<String> smartQuery(String query);
}

class AttendanceInsight {
  final String insight;
  final List<String> actions;

  AttendanceInsight({required this.insight, required this.actions});

  factory AttendanceInsight.fromJson(Map<String, dynamic> json) {
    return AttendanceInsight(
      insight: json['insight'] as String? ?? 'No insight available.',
      actions: (json['actions'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

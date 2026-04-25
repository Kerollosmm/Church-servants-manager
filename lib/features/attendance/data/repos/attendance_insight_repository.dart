import 'package:church_management_system/features/attendance/domain/repos/i_attendance_insight_repository.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AttendanceInsightRepository implements IAttendanceInsightRepository {
  final FirebaseFunctions _functions;

  AttendanceInsightRepository({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  @override
  Future<AttendanceInsight> getGroupInsight({
    required String groupId,
    required String question,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('getAttendanceInsight')
          .call({'groupId': groupId, 'question': question});

      return AttendanceInsight.fromJson(
        Map<String, dynamic>.from(result.data as Map),
      );
    } catch (e) {
      // TODO: Map to domain failure per P13
      throw Exception('Failed to fetch group insight: $e');
    }
  }

  @override
  Future<String?> getStudentEncouragement({required String studentId}) async {
    try {
      // US-03 implementation (Phase 5)
      final result = await _functions
          .httpsCallable('getStudentEncouragement')
          .call({'studentId': studentId});

      return result.data['encouragement'] as String?;
    } catch (e) {
      return null;
    }
  }
}

import 'package:church_management_system/features/attendance/domain/repos/i_attendance_insight_repository.dart';

class GetGroupInsightUseCase {
  final IAttendanceInsightRepository _repository;

  GetGroupInsightUseCase(this._repository);

  Future<AttendanceInsight> call({
    required String groupId,
    required String question,
  }) {
    return _repository.getGroupInsight(groupId: groupId, question: question);
  }
}

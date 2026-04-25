import 'package:church_management_system/features/attendance/domain/repos/i_attendance_insight_repository.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/smart_query_chat_panel.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_assistant_state.freezed.dart';

@freezed
class AIAssistantState with _$AIAssistantState {
  const factory AIAssistantState({
    @Default([]) List<ChatMessage> messages,
    @Default(false) bool isLoading,
    String? errorMessage,
    AttendanceInsight? lastInsight,
  }) = _AIAssistantState;
}

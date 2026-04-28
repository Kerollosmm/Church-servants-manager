import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_assistant_event.freezed.dart';

@freezed
class AIAssistantEvent with _$AIAssistantEvent {
  const factory AIAssistantEvent.getGroupInsight({
    required String groupId,
    required String question,
  }) = GetGroupInsight;

  const factory AIAssistantEvent.sendQuery({required String query}) = SendQuery;

  const factory AIAssistantEvent.clearChat() = ClearChat;
}

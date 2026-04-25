import 'package:church_management_system/features/attendance/domain/repos/i_attendance_insight_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/ai_assistant/ai_assistant_event.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/ai_assistant/ai_assistant_state.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/smart_query_chat_panel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AIAssistantBloc extends Bloc<AIAssistantEvent, AIAssistantState> {
  final IAttendanceInsightRepository _repository;

  AIAssistantBloc(this._repository) : super(const AIAssistantState()) {
    on<AIAssistantEvent>((event, emit) async {
      switch (event) {
        case GetGroupInsight():
          await _onGetGroupInsight(event.groupId, event.question, emit);
        case SendQuery():
          await _onSendQuery(event.query, emit);
        case ClearChat():
          _onClearChat(emit);
      }
    });
  }

  Future<void> _onGetGroupInsight(
    String groupId,
    String question,
    Emitter<AIAssistantState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final insight = await _repository.getGroupInsight(
        groupId: groupId,
        question: question,
      );
      emit(state.copyWith(isLoading: false, lastInsight: insight));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onSendQuery(
    String query,
    Emitter<AIAssistantState> emit,
  ) async {
    final userMessage = ChatMessage(
      text: query,
      isUser: true,
      timestamp: DateTime.now(),
    );

    emit(
      state.copyWith(
        messages: [...state.messages, userMessage],
        isLoading: true,
        errorMessage: null,
      ),
    );

    try {
      // US-02: Use the repository to send the query
      await Future.delayed(const Duration(seconds: 1));

      final assistantMessage = ChatMessage(
        text:
            'I understood your query: "$query". I am finding the matching students...',
        isUser: false,
        timestamp: DateTime.now(),
      );

      emit(
        state.copyWith(
          isLoading: false,
          messages: [...state.messages, assistantMessage],
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void _onClearChat(Emitter<AIAssistantState> emit) {
    emit(state.copyWith(messages: []));
  }
}

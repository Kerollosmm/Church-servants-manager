import 'dart:convert';
import 'dart:developer' as developer;

import 'package:church_management_system/features/attendance/domain/repos/i_attendance_insight_repository.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Service for client-side AI processing using Gemini.
/// Replaces Cloud Functions for Spark plan compatibility.
class StudentAIService {
  final String _apiKey;
  late final GenerativeModel _model;

  StudentAIService({required String apiKey}) : _apiKey = apiKey {
    _model = GenerativeModel(model: 'gemini-2.0-flash-lite', apiKey: _apiKey);
  }

  /// US-01: Servant Get Trend Insight
  Future<AttendanceInsight> getGroupInsight({
    required String groupName,
    required Map<String, dynamic> groupSummary,
    required String question,
  }) async {
    final prompt =
        '''
      You are an AI assistant for a church attendance system.
      Current Group: $groupName
      Aggregated Metrics: ${jsonEncode(groupSummary)}
      
      User Question: "$question"

      Instructions:
      - Provide a concise (2-3 sentences) analysis of the attendance trends.
      - Identify any significant drops or positive streaks.
      - DO NOT use individual student names if they were not provided in the metrics.
      - Suggest 2 actionable steps for the servant.
      - Return a JSON object with keys "insight" (string) and "actions" (array of strings).
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      final cleanJson = jsonMatch?.group(0) ?? text;
      final data = jsonDecode(cleanJson) as Map<String, dynamic>;

      return AttendanceInsight(
        insight: data['insight'] ?? 'No insight generated.',
        actions: List<String>.from(data['actions'] ?? []),
      );
    } catch (e) {
      developer.log('AI Insight Error', error: e, name: 'StudentAIService');
      throw Exception('Failed to generate AI insight locally.');
    }
  }

  /// US-03: Student Get Encouragement
  Future<String> getStudentEncouragement({
    required String studentName,
    required Map<String, dynamic> summary,
  }) async {
    final name = studentName.trim();
    final firstName = name.isNotEmpty
        ? name.split(RegExp(r'\s+'))[0]
        : 'Student';
    final prompt =
        '''
      You are a supportive church youth leader.
      Student Name: $firstName
      Attendance Summary: ${jsonEncode(summary)}
      Instructions:
      - Write a short, friendly, and motivational message (1-2 sentences) based on their attendance.
      - If they have a high streak, congratulate them.
      - If they missed sessions, give gentle encouragement to return.
      - Return a JSON object with key "encouragement" (string).
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      final cleanJson = jsonMatch?.group(0) ?? text;
      final data = jsonDecode(cleanJson) as Map<String, dynamic>;

      return data['encouragement'] ?? 'Keep growing in faith and fellowship!';
    } catch (e) {
      developer.log('Student AI Error', error: e, name: 'StudentAIService');
      return 'We are so glad to have you in our community! See you next time.';
    }
  }

  /// US-02: Smart Query Assistant
  Future<String> smartQuery(String query) async {
    final prompt =
        '''
      You are a helpful and knowledgeable AI assistant for a church attendance management system.
      A user has asked the following query: "$query"
      
      Please provide a concise, helpful response based on general knowledge of church management systems.
      If it's about checking who is absent, explain that they can check the history or reports.
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ??
          'I am sorry, I could not generate an answer at this time.';
    } catch (e) {
      developer.log('Smart Query AI Error', error: e, name: 'StudentAIService');
      throw Exception('Failed to process smart query.');
    }
  }
}

import 'dart:developer' as developer;
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_insight_repository.dart';
import 'package:church_management_system/features/student/data/services/student_ai_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceInsightRepository implements IAttendanceInsightRepository {
  final StudentAIService _aiService;
  final FirebaseFirestore _db;

  AttendanceInsightRepository({
    required StudentAIService aiService,
    FirebaseFirestore? firestore,
  }) : _aiService = aiService,
       _db = firestore ?? FirebaseFirestore.instance;

  @override
  Future<AttendanceInsight> getGroupInsight({
    required String groupId,
    required String question,
  }) async {
    try {
      // 1. Fetch group data for context
      final groupDoc = await _db
          .collection(FirestoreCollections.classes)
          .doc(groupId)
          .get();
      if (!groupDoc.exists) {
        throw Exception('Group not found.');
      }

      final groupData = groupDoc.data()!;
      final groupName = groupData['name'] ?? groupId;
      final groupSummary = Map<String, dynamic>.from(
        groupData['groupAttendanceSummary'] ?? {},
      );

      // 2. Call local AI service
      return await _aiService.getGroupInsight(
        groupName: groupName,
        groupSummary: groupSummary,
        question: question,
      );
    } catch (e) {
      throw Exception('Failed to fetch group insight locally: $e');
    }
  }

  @override
  Future<String?> getStudentEncouragement({required String studentId}) async {
    try {
      // 1. Fetch student data
      final studentDoc = await _db
          .collection(FirestoreCollections.students)
          .doc(studentId)
          .get();
      if (!studentDoc.exists) return null;

      final studentData = studentDoc.data()!;
      final studentName = studentData['name'] ?? 'Student';
      final summary = Map<String, dynamic>.from(
        studentData['attendanceSummary'] ?? {},
      );

      // 2. Call local AI service
      return await _aiService.getStudentEncouragement(
        studentName: studentName,
        summary: summary,
      );
    } catch (e, stack) {
      developer.log(
        'AttendanceInsightRepository.generateMessage error:',
        error: e,
        stackTrace: stack,
        name: 'AttendanceInsightRepository',
      );
      return 'We are so glad to have you in our community! See you next time.';
    }
  }

  @override
  Future<String> smartQuery(
    String query, {
    Map<String, dynamic>? contextData,
  }) async {
    try {
      return await _aiService.smartQuery(query, contextData: contextData);
    } catch (e, stack) {
      developer.log(
        'AttendanceInsightRepository.smartQuery error:',
        error: e,
        stackTrace: stack,
        name: 'AttendanceInsightRepository',
      );
      throw Exception('Failed to process smart query locally: $e');
    }
  }
}

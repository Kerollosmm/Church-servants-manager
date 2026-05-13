import 'package:church_management_system/features/results/data/models/results_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class IResultsRepository {
  Future<List<ResultsModel>> getResultsForServant(
    String groupId, {
    DocumentSnapshot? startAfter,
  });
  Future<ResultsModel?> getResultForStudent(String studentId);
  Future<void> updateResult(ResultsModel result);
  Future<void> syncOfflineUpdate(Map<String, dynamic> payload);
}

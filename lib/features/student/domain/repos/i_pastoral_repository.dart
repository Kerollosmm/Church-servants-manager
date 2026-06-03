import 'package:church_management_system/features/student/data/models/pastoral_record_model.dart';

/// Domain interface for pastoral care repository.
///
/// Enables dependency inversion: presentation and domain layers depend on
/// this abstraction, not concrete Firebase implementations.
abstract class IPastoralRepository {
  /// Creates a pastoral record in Firestore.
  ///
  /// Called by the sync engine after offline queue replay.
  Future<void> syncOfflineCreate(Map<String, dynamic> payload);

  /// Returns all pastoral records for a student, ordered by createdAt desc.
  Future<List<PastoralRecordModel>> getRecordsForStudent(String studentId);

  /// Returns all pastoral records across all students (admin view).
  Future<List<PastoralRecordModel>> getAllRecords({int limit});
}

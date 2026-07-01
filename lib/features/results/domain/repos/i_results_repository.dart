import 'package:church_management_system/core/utils/pagination_cursor.dart';
import 'package:church_management_system/features/results/domain/entities/result.dart';

abstract class IResultsRepository {
  Future<({List<Result> results, bool isFromCache})> getResultsForServant(
    String groupId, {
    PaginationCursor? startAfter,
  });
  Future<Result?> getResultForStudent(String studentId);
  Future<void> updateResult(Result result);
  Future<void> syncOfflineUpdate(Map<String, dynamic> payload);
}

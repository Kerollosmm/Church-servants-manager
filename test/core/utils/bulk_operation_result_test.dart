import 'package:church_management_system/core/utils/bulk_operation_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BulkOperationResult', () {
    test('should correctly calculate totalCount', () {
      final result = BulkOperationResult<int>(
        successfulItems: [1, 2],
        failedItems: [3],
      );

      expect(result.totalCount, 3);
    });

    test('should correctly calculate totalCount when empty', () {
      final result = BulkOperationResult<int>(
        successfulItems: [],
        failedItems: [],
      );

      expect(result.totalCount, 0);
    });

    group('isCompleteSuccess', () {
      test(
        'should return true when all items succeeded and totalCount > 0',
        () {
          final result = BulkOperationResult<int>(
            successfulItems: [1, 2],
            failedItems: [],
          );

          expect(result.isCompleteSuccess, isTrue);
        },
      );

      test('should return false when some items failed', () {
        final result = BulkOperationResult<int>(
          successfulItems: [1],
          failedItems: [2],
        );

        expect(result.isCompleteSuccess, isFalse);
      });

      test('should return false when totalCount is 0', () {
        final result = BulkOperationResult<int>(
          successfulItems: [],
          failedItems: [],
        );

        expect(result.isCompleteSuccess, isFalse);
      });
    });

    group('isCompleteFailure', () {
      test('should return true when all items failed and totalCount > 0', () {
        final result = BulkOperationResult<int>(
          successfulItems: [],
          failedItems: [1, 2],
        );

        expect(result.isCompleteFailure, isTrue);
      });

      test('should return false when some items succeeded', () {
        final result = BulkOperationResult<int>(
          successfulItems: [1],
          failedItems: [2],
        );

        expect(result.isCompleteFailure, isFalse);
      });

      test('should return false when totalCount is 0', () {
        final result = BulkOperationResult<int>(
          successfulItems: [],
          failedItems: [],
        );

        expect(result.isCompleteFailure, isFalse);
      });
    });

    test('should store errorMessage correctly', () {
      const error = 'Some error occurred';
      final result = BulkOperationResult<int>(
        successfulItems: [],
        failedItems: [],
        errorMessage: error,
      );

      expect(result.errorMessage, error);
    });

    test('should have unmodifiable successfulItems list', () {
      final successful = [1, 2];
      final result = BulkOperationResult<int>(
        successfulItems: successful,
        failedItems: [],
      );

      expect(() => result.successfulItems.add(3), throwsUnsupportedError);
    });

    test('should have unmodifiable failedItems list', () {
      final failed = [1, 2];
      final result = BulkOperationResult<int>(
        successfulItems: [],
        failedItems: failed,
      );

      expect(() => result.failedItems.add(3), throwsUnsupportedError);
    });
  });
}

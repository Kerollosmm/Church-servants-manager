/// Result of a bulk operation containing successes and failures.
class BulkOperationResult<T> {
  BulkOperationResult({
    required List<T> successfulItems,
    required List<T> failedItems,
    this.errorMessage,
  }) : successfulItems = List.unmodifiable(successfulItems),
       failedItems = List.unmodifiable(failedItems);

  /// Items that were processed successfully.
  final List<T> successfulItems;

  /// Items that failed processing.
  final List<T> failedItems;

  /// Optional top-level error message.
  final String? errorMessage;

  /// Returns true if all items were successful.
  bool get isCompleteSuccess => totalCount > 0 && failedItems.isEmpty;

  /// Returns true if all items failed.
  bool get isCompleteFailure => totalCount > 0 && successfulItems.isEmpty;

  /// Total number of items processed.
  int get totalCount => successfulItems.length + failedItems.length;
}

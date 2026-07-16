import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper to chunk large lists of Firestore write operations into multiple batches
/// to stay under the Firestore limit of 500 operations per write batch.
Future<void> chunkedBatch({
  required FirebaseFirestore firestore,
  required List<void Function(WriteBatch batch)> ops,
  int chunkSize = 450,
}) async {
  if (ops.isEmpty) return;
  for (var i = 0; i < ops.length; i += chunkSize) {
    final batch = firestore.batch();
    final chunk = ops.sublist(i, (i + chunkSize).clamp(0, ops.length));
    for (final op in chunk) {
      op(batch);
    }
    await batch.commit();
  }
}

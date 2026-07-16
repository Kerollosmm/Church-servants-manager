import 'package:church_management_system/core/services/firestore_batch_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  group('firestore_batch_util', () {
    test('chunkedBatch commits operations in chunks', () async {
      final docRefs = List.generate(
        10,
        (i) => firestore.collection('test_coll').doc('doc_$i'),
      );

      final ops = docRefs
          .map<void Function(WriteBatch)>(
            (ref) =>
                (batch) => batch.set(ref, {'value': ref.id}),
          )
          .toList();

      await chunkedBatch(
        firestore: firestore,
        ops: ops,
        chunkSize: 4, // Split 10 operations into 3 batches (4, 4, 2)
      );

      for (var i = 0; i < 10; i++) {
        final snap = await firestore
            .collection('test_coll')
            .doc('doc_$i')
            .get();
        expect(snap.exists, isTrue);
        expect(snap.data()?['value'], 'doc_$i');
      }
    });

    test('chunkedBatch does not crash with empty operations list', () async {
      await expectLater(chunkedBatch(firestore: firestore, ops: []), completes);
    });
  });
}

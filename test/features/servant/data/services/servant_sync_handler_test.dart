import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/features/servant/data/services/servant_sync_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late ServantSyncHandler syncHandler;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    syncHandler = ServantSyncHandler(firestore: fakeFirestore);
  });

  group('ServantSyncHandler unit tests', () {
    group('CREATE_SERVANT & UPDATE_SERVANT', () {
      test(
        'upserts servant document with parsed timestamps and server timestamp',
        () async {
          final entry = SyncEntry(
            id: 'sync_1',
            actionType: 'CREATE_SERVANT',
            payload: {
              'docId': 'servant_123',
              'name': 'John Doe',
              'email': 'john@example.com',
              'role': 'servant',
              'createdAt': '2026-05-10T12:00:00.000Z',
            },
            createdAt: DateTime.now(),
          );

          await syncHandler.execute(entry);

          final docSnap = await fakeFirestore
              .collection(FirestoreCollections.servants)
              .doc('servant_123')
              .get();

          expect(docSnap.exists, isTrue);
          final data = docSnap.data()!;
          expect(data['name'], equals('John Doe'));
          expect(data['email'], equals('john@example.com'));
          expect(data['docId'], isNull); // Removed from payload during upsert
          expect(data['createdAt'], isA<Timestamp>());
          expect(
            (data['createdAt'] as Timestamp).toDate().toUtc(),
            equals(DateTime.parse('2026-05-10T12:00:00.000Z')),
          );
          expect(data['updatedAt'], isNotNull);
        },
      );

      test(
        'returns early without throw when docId is missing in payload',
        () async {
          final entry = SyncEntry(
            id: 'sync_invalid',
            actionType: 'UPDATE_SERVANT',
            payload: {'name': 'No ID'},
            createdAt: DateTime.now(),
          );

          await syncHandler.execute(entry);

          final collectionSnap = await fakeFirestore
              .collection(FirestoreCollections.servants)
              .get();
          expect(collectionSnap.docs, isEmpty);
        },
      );
    });

    group('ARCHIVE_SERVANT', () {
      test('sets isArchived to true and records archive user id', () async {
        final entry = SyncEntry(
          id: 'sync_archive',
          actionType: 'ARCHIVE_SERVANT',
          payload: {'docId': 'servant_456', 'archivedByUserId': 'admin_1'},
          createdAt: DateTime.now(),
        );

        await syncHandler.execute(entry);

        final docSnap = await fakeFirestore
            .collection(FirestoreCollections.servants)
            .doc('servant_456')
            .get();

        expect(docSnap.exists, isTrue);
        final data = docSnap.data()!;
        expect(data['isArchived'], isTrue);
        expect(data['archivedByUserId'], equals('admin_1'));
        expect(data['archivedAt'], isNotNull);
        expect(data['updatedAt'], isNotNull);
      });

      test('returns early when docId is empty', () async {
        final entry = SyncEntry(
          id: 'sync_archive_empty',
          actionType: 'ARCHIVE_SERVANT',
          payload: {'docId': ''},
          createdAt: DateTime.now(),
        );

        await syncHandler.execute(entry);
        final collectionSnap = await fakeFirestore
            .collection(FirestoreCollections.servants)
            .get();
        expect(collectionSnap.docs, isEmpty);
      });
    });

    group('RESTORE_SERVANT', () {
      test(
        'sets isArchived to false and updates team assignments if provided',
        () async {
          final entry = SyncEntry(
            id: 'sync_restore',
            actionType: 'RESTORE_SERVANT',
            payload: {
              'docId': 'servant_789',
              'restoredByUserId': 'admin_2',
              'assignedTeamId': 'team_A',
              'assignedTeamIds': ['team_A', 'team_B'],
            },
            createdAt: DateTime.now(),
          );

          await syncHandler.execute(entry);

          final docSnap = await fakeFirestore
              .collection(FirestoreCollections.servants)
              .doc('servant_789')
              .get();

          expect(docSnap.exists, isTrue);
          final data = docSnap.data()!;
          expect(data['isArchived'], isFalse);
          expect(data['restoredByUserId'], equals('admin_2'));
          expect(data['assignedTeamId'], equals('team_A'));
          expect(data['assignedTeamIds'], equals(['team_A', 'team_B']));
          expect(data['restoredAt'], isNotNull);
          expect(data['updatedAt'], isNotNull);
        },
      );
    });

    group('Batch execution & Unsupported actions', () {
      test('throws UnimplementedError for unsupported action types', () async {
        final entry = SyncEntry(
          id: 'unknown_action',
          actionType: 'DELETE_PERMANENT',
          payload: {'docId': 'servant_123'},
          createdAt: DateTime.now(),
        );

        expect(
          () => syncHandler.execute(entry),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('executeBatch executes multiple entries concurrently', () async {
        final entries = [
          SyncEntry(
            id: 'batch_1',
            actionType: 'CREATE_SERVANT',
            payload: {'docId': 'b_1', 'name': 'Servant One'},
            createdAt: DateTime.now(),
          ),
          SyncEntry(
            id: 'batch_2',
            actionType: 'CREATE_SERVANT',
            payload: {'docId': 'b_2', 'name': 'Servant Two'},
            createdAt: DateTime.now(),
          ),
        ];

        await syncHandler.executeBatch(entries);

        final doc1 = await fakeFirestore
            .collection(FirestoreCollections.servants)
            .doc('b_1')
            .get();
        final doc2 = await fakeFirestore
            .collection(FirestoreCollections.servants)
            .doc('b_2')
            .get();

        expect(doc1.exists, isTrue);
        expect(doc2.exists, isTrue);
      });
    });
  });
}

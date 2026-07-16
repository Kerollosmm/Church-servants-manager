import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/features/student/data/services/student_sync_handler.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStudentRepository extends Mock implements IStudentRepository {}

void main() {
  late MockStudentRepository mockRepo;
  late StudentSyncHandler handler;

  setUpAll(() {
    registerFallbackValue(
      SyncEntry(
        id: 'fallback',
        actionType: 'UPSERT_STUDENT',
        payload: {},
        createdAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockRepo = MockStudentRepository();
    handler = StudentSyncHandler(mockRepo);
  });

  group('StudentSyncHandler', () {
    test('executeBatch delegates to repository', () async {
      final entries = [
        SyncEntry(
          id: '1',
          actionType: 'UPSERT_STUDENT',
          payload: {
            'student': {'docID': 's1', 'name': 'Mina'},
          },
          createdAt: DateTime.now(),
        ),
      ];

      when(() => mockRepo.syncBatchedStudents(any())).thenAnswer((_) async {});

      await handler.executeBatch(entries);

      verify(() => mockRepo.syncBatchedStudents(entries)).called(1);
    });

    // P0-2 regression: old queue entries written before the rename still carry
    // actionType CREATE_STUDENT_WITH_AUTH and a `password` field. The handler
    // must route them through the invitation flow and strip the password so it
    // never reaches the repository.
    test(
      'strips legacy password from CREATE_STUDENT_WITH_AUTH entry and routes to syncOfflineCreateWithAuth',
      () async {
        final legacyEntry = SyncEntry(
          id: 'legacy-1',
          actionType: 'CREATE_STUDENT_WITH_AUTH',
          payload: {
            'student': {'docID': 's1', 'name': 'Mina'},
            'password': 'super-secret-legacy-value',
          },
          createdAt: DateTime.now(),
        );

        Map<String, dynamic>? capturedPayload;
        when(() => mockRepo.syncOfflineCreateWithAuth(any())).thenAnswer((
          inv,
        ) async {
          capturedPayload = Map<String, dynamic>.from(
            inv.positionalArguments[0] as Map<String, dynamic>,
          );
        });

        await handler.execute(legacyEntry);

        verify(() => mockRepo.syncOfflineCreateWithAuth(any())).called(1);
        expect(capturedPayload, isNotNull);
        expect(
          capturedPayload!.containsKey('password'),
          isFalse,
          reason: 'password must be stripped before reaching the repository',
        );
        expect(capturedPayload!['student'], {'docID': 's1', 'name': 'Mina'});
      },
    );

    test(
      'strips legacy password from CREATE_STUDENT_INVITATION entry',
      () async {
        final entry = SyncEntry(
          id: 'inv-1',
          actionType: 'CREATE_STUDENT_INVITATION',
          payload: {
            'student': {'docID': 's2', 'name': 'Sara'},
            'password': 'another-secret',
          },
          createdAt: DateTime.now(),
        );

        Map<String, dynamic>? capturedPayload;
        when(() => mockRepo.syncOfflineCreateWithAuth(any())).thenAnswer((
          inv,
        ) async {
          capturedPayload = Map<String, dynamic>.from(
            inv.positionalArguments[0] as Map<String, dynamic>,
          );
        });

        await handler.execute(entry);

        verify(() => mockRepo.syncOfflineCreateWithAuth(any())).called(1);
        expect(capturedPayload!.containsKey('password'), isFalse);
      },
    );
  });
}

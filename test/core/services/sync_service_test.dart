import 'dart:async';
import 'dart:io';

import 'package:church_management_system/core/constants/sync_action_type.dart';
import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/dead_letter_queue.dart';
import 'package:church_management_system/core/services/sync_handler.dart';
import 'package:church_management_system/core/services/sync_service.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_session_repository.dart';
import 'package:church_management_system/features/attendance/data/services/attendance_season_sync_handler.dart';
import 'package:church_management_system/features/results/data/services/result_sync_handler.dart';
import 'package:church_management_system/features/results/domain/repos/i_results_repository.dart';
import 'package:church_management_system/features/student/data/services/pastoral_sync_handler.dart';
import 'package:church_management_system/features/student/data/services/student_sync_handler.dart';
import 'package:church_management_system/features/student/domain/repos/i_pastoral_repository.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockStudentRepository extends Mock implements IStudentRepository {}

class MockResultsRepository extends Mock implements IResultsRepository {}

class MockSessionRepository extends Mock
    implements AttendanceSessionRepository {}

class MockPastoralRepository extends Mock implements IPastoralRepository {}

class MockConnectivity extends Mock implements Connectivity {}

class MockDeadLetterQueue extends Mock implements DeadLetterQueue {}

class MockSyncHandler extends Mock implements SyncHandler {}

void main() {
  late MockStudentRepository studentRepo;
  late MockResultsRepository resultsRepo;
  late MockSessionRepository sessionRepo;
  late MockPastoralRepository pastoralRepo;
  late MockConnectivity connectivity;
  late MockDeadLetterQueue mockDlq;
  late MockSyncHandler mockAttendanceHandler;
  late SyncService syncService;
  SyncEntry entry({required String id, String actionType = 'MARK_ATTENDANCE'}) {
    return SyncEntry(
      id: id,
      actionType: actionType,
      payload: {
        'teamId': 'team-1',
        'sessionId': 'session-1',
        'studentId': 'student-1',
      },
      createdAt: DateTime.now(),
    );
  }

  setUpAll(() {
    Hive.init(Directory.systemTemp.createTempSync('hive_test_').path);
    Hive.registerAdapter(SyncEntryAdapter());
    registerFallbackValue(
      SyncEntry(
        id: 'fallback',
        actionType: 'MARK_ATTENDANCE',
        payload: {},
        createdAt: DateTime.now(),
      ),
    );
  });
  setUp(() async {
    studentRepo = MockStudentRepository();
    resultsRepo = MockResultsRepository();
    sessionRepo = MockSessionRepository();
    pastoralRepo = MockPastoralRepository();
    connectivity = MockConnectivity();
    mockDlq = MockDeadLetterQueue();
    mockAttendanceHandler = MockSyncHandler();
    when(() => mockDlq.init()).thenAnswer((_) async {});
    when(() => mockDlq.add(any())).thenAnswer((_) async {});
    when(
      () => connectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.none]);
    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream.empty());
    syncService = SyncService(
      deadLetterQueue: mockDlq,
      connectivity: connectivity,
      backoffProvider: (_) => Duration.zero,
      handlers: {
        SyncActionType.markAttendance: mockAttendanceHandler,
        SyncActionType.clearAttendance: mockAttendanceHandler,
        SyncActionType.upsertStudent: StudentSyncHandler(studentRepo),
        SyncActionType.archiveStudent: StudentSyncHandler(studentRepo),
        SyncActionType.restoreStudent: StudentSyncHandler(studentRepo),
        SyncActionType.updateResult: ResultsSyncHandler(resultsRepo),
        SyncActionType.createSession: AttendanceSessionSyncHandler(sessionRepo),
        SyncActionType.closeSession: AttendanceSessionSyncHandler(sessionRepo),
        SyncActionType.createPastoralRecord: PastoralSyncHandler(pastoralRepo),
      },
    );
    await syncService.init();
    await syncService.setAuthenticatedUser('test_user');
  });
  group('enqueue', () {
    test('adds entry to the sync queue box', () async {
      final syncEntry = entry(id: 'test_1');
      await syncService.enqueue(syncEntry);
      final box = Hive.box<SyncEntry>('sync_queue_test_user');
      expect(box.get('test_1'), isNotNull);
    });
    test('deduplicates entries with same id', () async {
      final first = entry(id: 'dedup_1');
      final second = entry(id: 'dedup_1');
      await syncService.enqueue(first);
      await syncService.enqueue(second);
      final box = Hive.box<SyncEntry>('sync_queue_test_user');
      expect(box.length, 1);
    });
  });
  group('processQueue', () {
    test('does nothing when queue is empty', () async {
      await expectLater(syncService.processQueue(), completes);
    });
    test('processes MARK_ATTENDANCE entries and removes them', () async {
      when(
        () => mockAttendanceHandler.executeBatch(any()),
      ).thenAnswer((_) async {});
      when(() => mockAttendanceHandler.execute(any())).thenAnswer((_) async {});
      await syncService.enqueue(entry(id: 'process_1'));
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      await syncService.processQueue();
      final box = Hive.box<SyncEntry>('sync_queue_test_user');
      expect(box.length, 0);
      verify(() => mockAttendanceHandler.executeBatch(any())).called(1);
    });
    test('increments retryCount on failure', () async {
      when(
        () => mockAttendanceHandler.executeBatch(any()),
      ).thenThrow(Exception('Network error'));
      when(
        () => mockAttendanceHandler.execute(any()),
      ).thenThrow(Exception('Network error'));
      await syncService.enqueue(entry(id: 'retry_1'));
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      await syncService.processQueue();
      final box = Hive.box<SyncEntry>('sync_queue_test_user');
      final updated = box.get('retry_1');
      expect(updated, isNotNull);
      expect(updated!.retryCount, 1);
    });
    test('drops entry after max retries (5)', () async {
      when(
        () => mockAttendanceHandler.executeBatch(any()),
      ).thenThrow(Exception('Network error'));
      when(
        () => mockAttendanceHandler.execute(any()),
      ).thenThrow(Exception('Network error'));
      await syncService.enqueue(entry(id: 'max_retry_1'));
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      for (var i = 0; i <= 5; i++) {
        await syncService.processQueue();
      }
      final box = Hive.box<SyncEntry>('sync_queue_test_user');
      expect(box.get('max_retry_1'), isNull);
    });
    test('processes entries in FIFO order', () async {
      final processed = <String>[];
      when(() => mockAttendanceHandler.executeBatch(any())).thenAnswer((
        _,
      ) async {
        processed.add('MARK_ATTENDANCE');
      });
      when(() => mockAttendanceHandler.execute(any())).thenAnswer((_) async {
        processed.add('MARK_ATTENDANCE');
      });
      when(() => studentRepo.syncOfflineUpsert(any())).thenAnswer((_) async {
        processed.add('UPSERT_STUDENT');
      });
      await syncService.enqueue(entry(id: 'fifo_1'));
      await syncService.enqueue(
        entry(id: 'fifo_2', actionType: 'UPSERT_STUDENT'),
      );
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      await syncService.processQueue();
      expect(processed, ['MARK_ATTENDANCE', 'UPSERT_STUDENT']);
    });
    test('routes UPSERT_STUDENT to student repository', () async {
      when(() => studentRepo.syncOfflineUpsert(any())).thenAnswer((_) async {});
      await syncService.enqueue(
        entry(id: 'route_1', actionType: 'UPSERT_STUDENT'),
      );
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      await syncService.processQueue();
      verify(() => studentRepo.syncOfflineUpsert(any())).called(1);
    });
    test('streams status updates during processing', () async {
      when(
        () => mockAttendanceHandler.executeBatch(any()),
      ).thenAnswer((_) async {});
      when(() => mockAttendanceHandler.execute(any())).thenAnswer((_) async {});
      await syncService.enqueue(entry(id: 'stream_1'));
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      final statuses = <SyncEngineStatus>[];
      syncService.statusStream.listen(statuses.add);
      await syncService.processQueue();
      expect(statuses.any((s) => s.isSyncing), isTrue);
    });
    test('local box reference isolation on user switch mid-flight', () async {
      final completer = Completer<void>();
      when(() => mockAttendanceHandler.executeBatch(any())).thenAnswer((
        _,
      ) async {
        await syncService.setAuthenticatedUser('user_b');
        completer.complete();
      });
      when(() => mockAttendanceHandler.execute(any())).thenAnswer((_) async {
        await syncService.setAuthenticatedUser('user_b');
        completer.complete();
      });
      await syncService.enqueue(entry(id: 'mid_flight_1'));
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      await syncService.processQueue();
      await completer.future;
      final boxA = await Hive.openBox<SyncEntry>('sync_queue_test_user');
      expect(boxA.get('mid_flight_1'), isNotNull);
      final boxB = Hive.box<SyncEntry>('sync_queue_user_b');
      expect(boxB.length, 0);
    });
    test(
      'circuit-breaker halts individual fallback loop on unavailable FirebaseException without penalizing subsequent items',
      () async {
        final entry1 = entry(id: 'batch_item_1');
        final entry2 = entry(id: 'batch_item_2');
        final entry3 = entry(id: 'batch_item_3');
        await syncService.enqueue(entry1);
        await syncService.enqueue(entry2);
        await syncService.enqueue(entry3);
        when(
          () => mockAttendanceHandler.executeBatch(any()),
        ).thenThrow(Exception('Batch failed'));
        when(() => mockAttendanceHandler.execute(any())).thenThrow(
          FirebaseException(plugin: 'firestore', code: 'unavailable'),
        );
        when(
          () => connectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);
        await syncService.processQueue();
        final box = Hive.box<SyncEntry>('sync_queue_test_user');
        expect(box.length, 3);
        expect(box.get('batch_item_1')?.retryCount, 0);
        expect(box.get('batch_item_2')?.retryCount, 0);
        expect(box.get('batch_item_3')?.retryCount, 0);
      },
    );
    test(
      'circuit-breaker halts individual fallback loop on network loss (connectivity_plus) without penalizing subsequent items',
      () async {
        final entry1 = entry(id: 'batch_item_1');
        final entry2 = entry(id: 'batch_item_2');
        await syncService.enqueue(entry1);
        await syncService.enqueue(entry2);
        when(
          () => mockAttendanceHandler.executeBatch(any()),
        ).thenThrow(Exception('Batch failed'));
        when(
          () => mockAttendanceHandler.execute(any()),
        ).thenAnswer((_) async {});
        var checkCount = 0;
        when(() => connectivity.checkConnectivity()).thenAnswer((_) async {
          checkCount++;
          if (checkCount >= 2) {
            return [ConnectivityResult.none];
          }
          return [ConnectivityResult.wifi];
        });
        await syncService.processQueue();
        final box = Hive.box<SyncEntry>('sync_queue_test_user');
        expect(box.length, 2);
        expect(box.get('batch_item_1')?.retryCount, 0);
        expect(box.get('batch_item_2')?.retryCount, 0);
      },
    );

    test('enqueue during active processQueue() triggers re-run', () async {
      final processed = <String>[];
      int callCount = 0;
      final completer = Completer<void>();

      when(() => studentRepo.syncOfflineUpsert(any())).thenAnswer((_) async {
        callCount++;
        processed.add('item_$callCount');
        if (callCount == 1) {
          await syncService.enqueue(
            SyncEntry(
              id: 'second_item',
              actionType: 'UPSERT_STUDENT',
              payload: {},
              createdAt: DateTime.now(),
            ),
          );
          completer.complete();
        }
      });

      await syncService.enqueue(
        SyncEntry(
          id: 'first_item',
          actionType: 'UPSERT_STUDENT',
          payload: {},
          createdAt: DateTime.now(),
        ),
      );

      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      await syncService.processQueue();
      await completer.future;

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final box = Hive.box<SyncEntry>('sync_queue_test_user');
      expect(box.length, 0);
      expect(processed, ['item_1', 'item_2']);
    });
  });
  tearDown(() async {
    if (Hive.isBoxOpen('sync_queue_box')) {
      final box = Hive.box<SyncEntry>('sync_queue_box');
      await box.clear();
    }
    final boxA = await Hive.openBox<SyncEntry>('sync_queue_test_user');
    await boxA.clear();
    await boxA.close();
    final boxB = await Hive.openBox<SyncEntry>('sync_queue_user_b');
    await boxB.clear();
    await boxB.close();
    syncService.dispose();
  });
}

import 'dart:async';
import 'dart:io';

import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/sync_service.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_session_repository.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/results/domain/repos/i_results_repository.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockAttendanceRepository extends Mock implements IAttendanceRepository {}

class MockStudentRepository extends Mock implements IStudentRepository {}

class MockResultsRepository extends Mock implements IResultsRepository {}

class MockSessionRepository extends Mock
    implements AttendanceSessionRepository {}

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MockAttendanceRepository attendanceRepo;
  late MockStudentRepository studentRepo;
  late MockResultsRepository resultsRepo;
  late MockSessionRepository sessionRepo;
  late MockConnectivity connectivity;
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
  });

  setUp(() async {
    attendanceRepo = MockAttendanceRepository();
    studentRepo = MockStudentRepository();
    resultsRepo = MockResultsRepository();
    sessionRepo = MockSessionRepository();
    connectivity = MockConnectivity();

    when(
      () => connectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.none]);
    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream.empty());

    syncService = SyncService(
      attendanceRepository: attendanceRepo,
      studentRepository: studentRepo,
      resultsRepository: resultsRepo,
      sessionRepository: sessionRepo,
      connectivity: connectivity,
    );

    await syncService.init();
  });

  group('enqueue', () {
    test('adds entry to the sync queue box', () async {
      final syncEntry = entry(id: 'test_1');

      await syncService.enqueue(syncEntry);

      final box = Hive.box<SyncEntry>('sync_queue_box');
      expect(box.get('test_1'), isNotNull);
    });

    test('deduplicates entries with same id', () async {
      final first = entry(id: 'dedup_1');
      final second = entry(id: 'dedup_1');

      await syncService.enqueue(first);
      await syncService.enqueue(second);

      final box = Hive.box<SyncEntry>('sync_queue_box');
      expect(box.length, 1);
    });
  });

  group('processQueue', () {
    test('does nothing when queue is empty', () async {
      await expectLater(syncService.processQueue(), completes);
    });

    test('processes MARK_ATTENDANCE entries and removes them', () async {
      when(
        () => attendanceRepo.syncOfflineMark(any()),
      ).thenAnswer((_) async {});

      await syncService.enqueue(entry(id: 'process_1'));
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      await syncService.processQueue();

      final box = Hive.box<SyncEntry>('sync_queue_box');
      expect(box.length, 0);
      verify(() => attendanceRepo.syncOfflineMark(any())).called(1);
    });

    test('increments retryCount on failure', () async {
      when(
        () => attendanceRepo.syncOfflineMark(any()),
      ).thenThrow(Exception('Network error'));

      await syncService.enqueue(entry(id: 'retry_1'));
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      await syncService.processQueue();

      final box = Hive.box<SyncEntry>('sync_queue_box');
      final updated = box.get('retry_1');
      expect(updated, isNotNull);
      expect(updated!.retryCount, 1);
    });

    test('drops entry after max retries (5)', () async {
      when(
        () => attendanceRepo.syncOfflineMark(any()),
      ).thenThrow(Exception('Persistent failure'));

      await syncService.enqueue(entry(id: 'max_retry_1'));
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      for (var i = 0; i <= 5; i++) {
        await syncService.processQueue();
      }

      final box = Hive.box<SyncEntry>('sync_queue_box');
      expect(box.get('max_retry_1'), isNull);
    });

    test('processes entries in FIFO order', () async {
      final processed = <String>[];
      when(() => attendanceRepo.syncOfflineMark(any())).thenAnswer((_) async {
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
        () => attendanceRepo.syncOfflineMark(any()),
      ).thenAnswer((_) async {});

      await syncService.enqueue(entry(id: 'stream_1'));
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      final statuses = <SyncStatus>[];
      syncService.statusStream.listen(statuses.add);
      await syncService.processQueue();

      expect(statuses.any((s) => s.isSyncing), isTrue);
    });
  });

  tearDown(() async {
    final box = Hive.box<SyncEntry>('sync_queue_box');
    await box.clear();
    syncService.dispose();
  });
}

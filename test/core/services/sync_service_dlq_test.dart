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
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncHandler extends Mock implements SyncHandler {}

class MockStudentRepository extends Mock implements IStudentRepository {}

class MockResultsRepository extends Mock implements IResultsRepository {}

class MockSessionRepository extends Mock
    implements AttendanceSessionRepository {}

class MockPastoralRepository extends Mock implements IPastoralRepository {}

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late Directory tempDir;
  late SyncService syncService;
  late DeadLetterQueue dlq;
  late MockSyncHandler mockAttendanceHandler;
  late MockStudentRepository mockStudent;
  late MockResultsRepository mockResults;
  late MockSessionRepository mockSession;
  late MockPastoralRepository mockPastoral;
  late MockConnectivity mockConnectivity;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('sync_dlq_test');
    Hive.init(tempDir.path);
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
    mockAttendanceHandler = MockSyncHandler();
    mockStudent = MockStudentRepository();
    mockResults = MockResultsRepository();
    mockSession = MockSessionRepository();
    mockPastoral = MockPastoralRepository();
    mockConnectivity = MockConnectivity();

    // Default to no connectivity so enqueue() does not trigger processQueue()
    when(
      () => mockConnectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.none]);
    when(
      () => mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream.empty());

    dlq = DeadLetterQueue();
    await dlq.init();

    syncService = SyncService(
      deadLetterQueue: dlq,
      connectivity: mockConnectivity,
      backoffProvider: (_) => Duration.zero,
      handlers: {
        SyncActionType.markAttendance: mockAttendanceHandler,
        SyncActionType.clearAttendance: mockAttendanceHandler,
        SyncActionType.upsertStudent: StudentSyncHandler(mockStudent),
        SyncActionType.archiveStudent: StudentSyncHandler(mockStudent),
        SyncActionType.restoreStudent: StudentSyncHandler(mockStudent),
        SyncActionType.updateResult: ResultsSyncHandler(mockResults),
        SyncActionType.createSession: AttendanceSessionSyncHandler(mockSession),
        SyncActionType.closeSession: AttendanceSessionSyncHandler(mockSession),
        SyncActionType.createPastoralRecord: PastoralSyncHandler(mockPastoral),
      },
    );
    await syncService.init();
    await syncService.setAuthenticatedUser('test_user');
  });

  tearDown(() async {
    syncService.dispose();
    // Clear both boxes between tests
    final testUserBox = await Hive.openBox<SyncEntry>('sync_queue_test_user');
    await testUserBox.clear();
    await testUserBox.close();
    await dlq.clear();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  group('SyncService DLQ integration', () {
    test('entry exceeding max retries is moved to DLQ, not deleted', () async {
      when(
        () => mockAttendanceHandler.execute(any()),
      ).thenThrow(Exception('persistent failure'));

      final entry = SyncEntry(
        id: 'dlq_test_1',
        actionType: 'MARK_ATTENDANCE',
        payload: {'studentId': 's1', 'sessionId': 'sess1'},
        createdAt: DateTime(2026),
      );
      await syncService.enqueue(entry);

      // Enable connectivity so processQueue() actually processes entries
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      for (var i = 0; i < 6; i++) {
        await syncService.processQueue();
      }

      expect(dlq.length, 1);
      expect(dlq.getAll().first.id, 'dlq_test_1');
      expect(dlq.getAll().first.failedAt, isNotNull);
    });

    test('entry that eventually succeeds does not go to DLQ', () async {
      var callCount = 0;
      when(() => mockAttendanceHandler.execute(any())).thenAnswer((_) async {
        callCount++;
        if (callCount <= 3) throw Exception('temporary network failure');
      });

      final entry = SyncEntry(
        id: 'backoff_test',
        actionType: 'MARK_ATTENDANCE',
        payload: {'studentId': 's1', 'sessionId': 'sess1'},
        createdAt: DateTime(2026),
      );
      await syncService.enqueue(entry);

      // Enable connectivity so processQueue() actually processes entries
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      for (var i = 0; i < 5; i++) {
        await syncService.processQueue();
      }

      expect(dlq.isEmpty, isTrue);
    });
  });
}

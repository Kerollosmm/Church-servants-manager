import 'dart:io';

import 'package:church_management_system/core/constants/sync_action_type.dart';
import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/dead_letter_queue.dart';
import 'package:church_management_system/core/services/sync_handler.dart';
import 'package:church_management_system/core/services/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockConnectivity extends Mock implements Connectivity {}

class MockSyncHandler extends Mock implements SyncHandler {}

void main() {
  late Directory tempDir;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockConnectivity mockConnectivity;
  late MockSyncHandler mockHandler;
  late DeadLetterQueue dlq;
  late SyncService syncService;

  setUpAll(() {
    if (!Hive.isAdapterRegistered(100)) {
      Hive.registerAdapter(SyncEntryAdapter());
    }
    registerFallbackValue(
      SyncEntry.create(
        id: 'fallback',
        action: SyncActionType.markAttendance,
        payload: {},
        createdAt: DateTime.now(),
      ),
    );
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('workmanager_test_');
    Hive.init(tempDir.path);

    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockConnectivity = MockConnectivity();
    mockHandler = MockSyncHandler();
    dlq = DeadLetterQueue();

    when(() => mockUser.uid).thenReturn('integration_test_user');
    when(() => mockAuth.currentUser).thenReturn(mockUser);

    syncService = SyncService(
      deadLetterQueue: dlq,
      connectivity: mockConnectivity,
      auth: mockAuth,
      backoffProvider: (_) => Duration.zero,
      handlers: {SyncActionType.markAttendance: mockHandler},
    );
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Workmanager Boot Synchronization Integration Tests', () {
    test(
      'Offline state - should NOT execute synchronization, entries stay in queue',
      () async {
        // 1. Arrange: Connectivity is offline, 1 pending item in queue
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.none]);

        await syncService.initAndProcessOnce();
        final syncEntry = SyncEntry.create(
          id: 'entry_offline',
          action: SyncActionType.markAttendance,
          payload: {'studentId': '123'},
          createdAt: DateTime.now(),
        );
        await syncService.enqueue(syncEntry);

        final queueBox = Hive.box<SyncEntry>(
          'sync_queue_integration_test_user',
        );
        expect(queueBox.length, 1);

        // 2. Act: Trigger Workmanager boot sync (still offline)
        await syncService.initAndProcessOnce();

        // 3. Assert: Handler was not called, queue is untouched
        verifyNever(() => mockHandler.execute(any()));
        expect(queueBox.length, 1);
        expect(queueBox.get('entry_offline')?.retryCount, 0);
      },
    );

    test(
      'Online state - executes synchronization successfully, removes resolved entry',
      () async {
        // 1. Arrange: Enqueue while offline to prevent immediate execution
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.none]);

        await syncService.initAndProcessOnce();
        final syncEntry = SyncEntry.create(
          id: 'entry_online',
          action: SyncActionType.markAttendance,
          payload: {'studentId': '123'},
          createdAt: DateTime.now(),
        );
        await syncService.enqueue(syncEntry);

        final queueBox = Hive.box<SyncEntry>(
          'sync_queue_integration_test_user',
        );
        expect(queueBox.length, 1);

        // Change connectivity to online, handler returns successfully
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(() => mockHandler.execute(any())).thenAnswer((_) async {});

        // 2. Act: Trigger Workmanager boot sync
        await syncService.initAndProcessOnce();

        // 3. Assert: Handler was executed and entry was removed from queue
        verify(() => mockHandler.execute(any())).called(1);
        expect(queueBox.length, 0);
      },
    );

    test(
      'Transient error state - increments retry count, updates message, keeps in queue',
      () async {
        // 1. Arrange: Enqueue while offline
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.none]);

        await syncService.initAndProcessOnce();
        final syncEntry = SyncEntry.create(
          id: 'entry_transient',
          action: SyncActionType.markAttendance,
          payload: {'studentId': '123'},
          createdAt: DateTime.now(),
        );
        await syncService.enqueue(syncEntry);

        final queueBox = Hive.box<SyncEntry>(
          'sync_queue_integration_test_user',
        );
        expect(queueBox.length, 1);

        // Change connectivity to online, handler throws retriable exception
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.mobile]);
        when(
          () => mockHandler.execute(any()),
        ).thenThrow(const SocketException('Transient network error'));

        // 2. Act: Trigger Workmanager boot sync
        await syncService.initAndProcessOnce();

        // 3. Assert: Handler was called, entry retry count incremented, still in queue
        verify(() => mockHandler.execute(any())).called(1);
        expect(queueBox.length, 1);

        final updatedEntry = queueBox.get('entry_transient')!;
        expect(updatedEntry.retryCount, 1);
        expect(updatedEntry.lastErrorMessage, contains('SocketException'));
      },
    );

    test(
      'Fatal / non-retriable error state - evicts entry to Dead-Letter Queue immediately',
      () async {
        // 1. Arrange: Enqueue while offline
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.none]);

        await syncService.initAndProcessOnce();
        final syncEntry = SyncEntry.create(
          id: 'entry_fatal',
          action: SyncActionType.markAttendance,
          payload: {'studentId': '123'},
          createdAt: DateTime.now(),
        );
        await syncService.enqueue(syncEntry);

        final queueBox = Hive.box<SyncEntry>(
          'sync_queue_integration_test_user',
        );
        expect(queueBox.length, 1);

        // Change connectivity to online, handler throws non-retriable (fatal) exception
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(
          () => mockHandler.execute(any()),
        ).thenThrow(Exception('Fatal application error - invalid payload'));

        // 2. Act: Trigger Workmanager boot sync
        await syncService.initAndProcessOnce();

        // 3. Assert: Entry is evicted from the queue box and exists in DLQ
        expect(queueBox.length, 0);
        expect(dlq.length, 1);
      },
    );
  });
}

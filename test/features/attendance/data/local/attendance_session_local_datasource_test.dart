import 'dart:io';

import 'package:church_management_system/features/attendance/data/local/attendance_session_local_datasource.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'attendance_session_ds_test',
    );
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(53)) {
      Hive.registerAdapter(AttendanceSessionModelAdapter());
    }
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(AttendanceSessionLocalDatasource.boxName);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  AttendanceSessionModel buildTestSession({
    required String id,
    String teamId = 'team-1',
    String title = 'Session 1',
  }) {
    return AttendanceSessionModel(
      id: id,
      teamId: teamId,
      title: title,
      dateKey: '2026-06-03',
      startsAt: DateTime(2026, 6, 3, 18),
      endsAt: DateTime(2026, 6, 3, 19),
      durationMinutes: 60,
      createdByUserId: 'user-1',
      createdByName: 'Servant 1',
      createdAt: DateTime(2026, 6, 3, 17),
      updatedAt: DateTime(2026, 6, 3, 17),
    );
  }

  group('AttendanceSessionLocalDatasource', () {
    late AttendanceSessionLocalDatasource datasource;

    setUp(() {
      datasource = AttendanceSessionLocalDatasource();
    });

    test('cacheSession and getCachedSessionById', () async {
      final session = buildTestSession(id: 's-1').toDomain();
      await datasource.cacheSession(session);

      final cached = await datasource.getCachedSessionById('s-1');
      expect(cached, isNotNull);
      expect(cached!.id, 's-1');
      expect(cached.title, 'Session 1');
    });

    test('cacheSessions and query methods', () async {
      final s1 = buildTestSession(
        id: 's-1',
        teamId: 't-1',
        title: 'A',
      ).toDomain();
      final s2 = buildTestSession(
        id: 's-2',
        teamId: 't-1',
        title: 'B',
      ).toDomain();
      final s3 = buildTestSession(
        id: 's-3',
        teamId: 't-2',
        title: 'C',
      ).toDomain();

      await datasource.cacheSessions([s1, s2, s3]);

      final t1All = await datasource.getCachedAllSessions('t-1');
      expect(t1All.length, 2);
      expect(t1All.any((s) => s.id == 's-1'), isTrue);
      expect(t1All.any((s) => s.id == 's-2'), isTrue);

      final t2All = await datasource.getCachedAllSessions('t-2');
      expect(t2All.length, 1);
      expect(t2All.first.id, 's-3');

      final active = await datasource.getCachedActiveSessions('t-1');
      expect(active.length, 2); // default isClosed: false
    });

    test('Migration fallback: handles legacy Box<String> gracefully', () async {
      // 1. Manually create a Box<String> mimicking legacy format
      final legacyBox = await Hive.openBox<String>(
        AttendanceSessionLocalDatasource.boxName,
      );
      await legacyBox.put('legacy-1', '{"id": "legacy-1", "title": "Legacy"}');
      await legacyBox.close();

      // 2. Initialize datasource (which opens Box<AttendanceSessionModel>)
      // It should detect the legacy string box, clear it, and open successfully as typed box.
      await datasource.init();

      // 3. Verify that reading from it does not crash (it should be empty/migrated)
      final session = await datasource.getCachedSessionById('legacy-1');
      expect(session, isNull);

      // 4. Verify we can successfully read/write new typed models
      final newSession = buildTestSession(id: 'new-1', title: 'New').toDomain();
      await datasource.cacheSession(newSession);

      final cached = await datasource.getCachedSessionById('new-1');
      expect(cached, isNotNull);
      expect(cached!.title, 'New');
    });
  });
}

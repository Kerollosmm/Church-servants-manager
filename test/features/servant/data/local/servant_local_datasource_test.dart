import 'dart:io';

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/servant/data/local/servant_local_datasource.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late ServantLocalDatasource datasource;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('servant_local_ds_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ServantModelAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(UserRoleAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }
  });

  setUp(() {
    datasource = ServantLocalDatasource();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(ServantLocalDatasource.boxName);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  ServantModel buildTestServant({
    required String docID,
    String name = 'Test Servant',
    String? teamName = 'Team Alpha',
    bool isArchived = false,
  }) {
    return ServantModel(
      docID: docID,
      name: name,
      teamName: teamName,
      isArchived: isArchived,
    );
  }

  group('ServantLocalDatasource unit tests', () {
    test('cacheServant and getCachedServantById', () async {
      final servant = buildTestServant(docID: 's1', name: 'John');
      await datasource.cacheServant(servant);

      final cached = await datasource.getCachedServantById('s1');
      expect(cached, isNotNull);
      expect(cached!.docID, equals('s1'));
      expect(cached.name, equals('John'));
    });

    test('cacheServants and getCachedServants with archive filtering', () async {
      final s1 = buildTestServant(docID: 's1', name: 'Active 1');
      final s2 = buildTestServant(docID: 's2', name: 'Active 2');
      final s3 = buildTestServant(docID: 's3', name: 'Archived 1', isArchived: true);

      await datasource.cacheServants([s1, s2, s3]);

      final activeServants = await datasource.getCachedServants();
      expect(activeServants.length, equals(2));
      expect(activeServants.any((s) => s.docID == 's1'), isTrue);
      expect(activeServants.any((s) => s.docID == 's2'), isTrue);
      expect(activeServants.any((s) => s.docID == 's3'), isFalse);

      final allServants = await datasource.getCachedServants(includeArchived: true);
      expect(allServants.length, equals(3));
    });

    test('getCachedServantsByGroup filters servants by teamName', () async {
      final s1 = buildTestServant(docID: 's1', teamName: 'GroupA');
      final s2 = buildTestServant(docID: 's2', teamName: 'GroupA');
      final s3 = buildTestServant(docID: 's3', teamName: 'GroupB');

      await datasource.cacheServants([s1, s2, s3]);

      final groupAServants = await datasource.getCachedServantsByGroup('GroupA');
      expect(groupAServants.length, equals(2));
      expect(groupAServants.any((s) => s.docID == 's1'), isTrue);
      expect(groupAServants.any((s) => s.docID == 's2'), isTrue);

      final groupBServants = await datasource.getCachedServantsByGroup('GroupB');
      expect(groupBServants.length, equals(1));
      expect(groupBServants.first.docID, equals('s3'));
    });

    test('removeCachedServant deletes entry from Hive box', () async {
      final servant = buildTestServant(docID: 's1');
      await datasource.cacheServant(servant);

      expect(await datasource.getCachedServantById('s1'), isNotNull);

      await datasource.removeCachedServant('s1');
      expect(await datasource.getCachedServantById('s1'), isNull);
    });
  });
}

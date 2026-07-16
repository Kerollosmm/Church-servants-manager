import 'dart:io';
import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/repos/invitations_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late InvitationsRepository repository;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('invitations_repo_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    repository = InvitationsRepository(firestore: firestore);
    if (Hive.isBoxOpen('invitation_by_email_cache')) {
      await Hive.box<String>('invitation_by_email_cache').clear();
    }
  });

  group('InvitationsRepository', () {
    test(
      'findByEmail fetches from firestore, caches, and returns invitation',
      () async {
        await firestore.collection('Invitations').doc('test@example.com').set({
          'email': 'test@example.com',
          'name': 'Test User',
          'role': 'servant',
          'status': 'pending',
        });

        final result = await repository.findByEmail('test@example.com');
        expect(result, isNotNull);
        expect(result!.email, 'test@example.com');
        expect(result.name, 'Test User');
        expect(result.role, UserRole.servant);

        // Verify cached in Hive
        final box = await Hive.openBox<String>('invitation_by_email_cache');
        expect(box.containsKey('test@example.com'), isTrue);
      },
    );

    test(
      'findByEmail returns cached value without hitting firestore within 1 hour',
      () async {
        await firestore.collection('Invitations').doc('test@example.com').set({
          'email': 'test@example.com',
          'name': 'Test User',
          'role': 'servant',
          'status': 'pending',
        });

        // Warm cache
        await repository.findByEmail('test@example.com');

        // Modify firestore (cached value shouldn't see this)
        await firestore.collection('Invitations').doc('test@example.com').set({
          'email': 'test@example.com',
          'name': 'Updated Name',
          'role': 'servant',
          'status': 'pending',
        });

        final result = await repository.findByEmail('test@example.com');
        expect(result!.name, 'Test User'); // Still the cached name
      },
    );

    test('findByEmail caches negative lookup (non-existent doc)', () async {
      final result1 = await repository.findByEmail('missing@example.com');
      expect(result1, isNull);

      // Verify cached in Hive
      final box = await Hive.openBox<String>('invitation_by_email_cache');
      expect(box.containsKey('missing@example.com'), isTrue);
    });
  });
}

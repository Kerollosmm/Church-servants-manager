import 'package:church_management_system/features/auth/domain/auth_freshness_policy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockSecureStorage secureStorage;

  setUp(() {
    secureStorage = MockSecureStorage();
    when(
      () => secureStorage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => null);
    when(
      () => secureStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => secureStorage.delete(key: any(named: 'key')),
    ).thenAnswer((_) async {});
  });

  group('AuthFreshnessPolicy - Cold Start Behavior', () {
    test(
      'cold start with stored timestamp < 15 min → canPerformWrites = true',
      () async {
        final now = DateTime(2026, 4, 11, 10);
        final storedAt = now.subtract(const Duration(minutes: 5)); // 5 min ago

        when(
          () => secureStorage.read(key: _kLastValidationKey),
        ).thenAnswer((_) async => storedAt.toIso8601String());

        final DateTime fakeNow = now;
        final policy = AuthFreshnessPolicy(
          nowProvider: () => fakeNow,
          secureStorage: secureStorage,
        );

        // Initialize — loads stored timestamp
        await policy.initialize();

        // Should allow writes (5 min < 15 min window)
        expect(policy.canPerformWrites, isTrue);
      },
    );

    test(
      'cold start with stored timestamp > 15 min → canPerformWrites = false',
      () async {
        final now = DateTime(2026, 4, 11, 10);
        final storedAt = now.subtract(
          const Duration(minutes: 20),
        ); // 20 min ago

        when(
          () => secureStorage.read(key: _kLastValidationKey),
        ).thenAnswer((_) async => storedAt.toIso8601String());

        final DateTime fakeNow = now;
        final policy = AuthFreshnessPolicy(
          nowProvider: () => fakeNow,
          secureStorage: secureStorage,
        );

        // Initialize — loads stored timestamp
        await policy.initialize();

        // Should deny writes (20 min > 15 min window)
        expect(policy.canPerformWrites, isFalse);
      },
    );

    test(
      'cold start with no stored timestamp → canPerformWrites = false',
      () async {
        when(
          () => secureStorage.read(key: _kLastValidationKey),
        ).thenAnswer((_) async => null);

        final now = DateTime(2026, 4, 11, 10);
        final policy = AuthFreshnessPolicy(
          nowProvider: () => now,
          secureStorage: secureStorage,
        );

        // Initialize — no timestamp found
        await policy.initialize();

        // Should deny writes (no validation recorded)
        expect(policy.canPerformWrites, isFalse);
      },
    );

    test('recordValidation persists timestamp to secure storage', () async {
      final now = DateTime(2026, 4, 11, 10);
      final policy = AuthFreshnessPolicy(
        nowProvider: () => now,
        secureStorage: secureStorage,
      );

      await policy.initialize();
      await policy.recordValidation();

      // Verify timestamp was written to secure storage
      verify(
        () => secureStorage.write(
          key: _kLastValidationKey,
          value: any(named: 'value'),
        ),
      ).called(1);
    });

    test('reset clears in-memory state AND secure storage', () async {
      final now = DateTime(2026, 4, 11, 10);
      final policy = AuthFreshnessPolicy(
        nowProvider: () => now,
        secureStorage: secureStorage,
      );

      await policy.initialize();
      await policy.recordValidation();

      // Verify can write
      expect(policy.canPerformWrites, isTrue);

      // Reset
      await policy.reset();

      // Verify can no longer write
      expect(policy.canPerformWrites, isFalse);

      // Verify secure storage was cleared
      verify(() => secureStorage.delete(key: _kLastValidationKey)).called(1);
    });

    test('before initialize, canPerformWrites returns false', () {
      final now = DateTime(2026, 4, 11, 10);
      final policy = AuthFreshnessPolicy(
        nowProvider: () => now,
        secureStorage: secureStorage,
      );

      // Without calling initialize, writes are denied
      expect(policy.canPerformWrites, isFalse);
    });

    test('timeRemaining returns correct value after cold start', () async {
      final now = DateTime(2026, 4, 11, 10);
      final storedAt = now.subtract(const Duration(minutes: 5)); // 5 min ago

      when(
        () => secureStorage.read(key: _kLastValidationKey),
      ).thenAnswer((_) async => storedAt.toIso8601String());

      final DateTime fakeNow = now;
      final policy = AuthFreshnessPolicy(
        nowProvider: () => fakeNow,
        secureStorage: secureStorage,
      );

      await policy.initialize();

      // 15 min window - 5 min elapsed = 10 min remaining
      expect(policy.timeRemaining, const Duration(minutes: 10));
    });

    test('timeRemaining returns zero after window expires', () async {
      final now = DateTime(2026, 4, 11, 10);
      final storedAt = now.subtract(const Duration(minutes: 20)); // 20 min ago

      when(
        () => secureStorage.read(key: _kLastValidationKey),
      ).thenAnswer((_) async => storedAt.toIso8601String());

      final DateTime fakeNow = now;
      final policy = AuthFreshnessPolicy(
        nowProvider: () => fakeNow,
        secureStorage: secureStorage,
      );

      await policy.initialize();

      // Window expired → zero remaining
      expect(policy.timeRemaining, Duration.zero);
    });
  });
}

/// Expose the constant for tests
const _kLastValidationKey = 'auth_freshness_last_validation_at';

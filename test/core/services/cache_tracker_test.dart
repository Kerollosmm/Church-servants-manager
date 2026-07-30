import 'package:church_management_system/core/services/cache_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testKey = 'test_query_key';
  const alternateKey = 'another_key';

  tearDown(() {
    CacheTracker.clear(testKey);
    CacheTracker.clear(alternateKey);
  });

  group('CacheTracker unit tests', () {
    test('shouldRevalidate returns true when key has not been fetched', () {
      expect(CacheTracker.shouldRevalidate(testKey), isTrue);
    });

    test('markFetched updates last fetch time and prevents immediate revalidation', () {
      CacheTracker.markFetched(testKey);
      expect(CacheTracker.shouldRevalidate(testKey), isFalse);
    });

    test('shouldRevalidate returns true when elapsed time exceeds maxAge', () {
      CacheTracker.markFetched(testKey);
      // Passing maxAge of Duration.zero means any non-negative duration will trigger revalidation
      expect(
        CacheTracker.shouldRevalidate(
          testKey,
          maxAge: const Duration(milliseconds: -1),
        ),
        isTrue,
      );
    });

    test('clear removes entry so shouldRevalidate returns true', () {
      CacheTracker.markFetched(testKey);
      expect(CacheTracker.shouldRevalidate(testKey), isFalse);

      CacheTracker.clear(testKey);
      expect(CacheTracker.shouldRevalidate(testKey), isTrue);
    });

    test('keys are tracked independently', () {
      CacheTracker.markFetched(testKey);
      expect(CacheTracker.shouldRevalidate(testKey), isFalse);
      expect(CacheTracker.shouldRevalidate(alternateKey), isTrue);
    });
  });
}

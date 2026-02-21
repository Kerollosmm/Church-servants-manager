import 'package:church_managment_system/core/utils/exception_matchers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isPermissionDeniedException', () {
    test('matches hyphenated permission denied', () {
      expect(isPermissionDeniedException('permission-denied'), isTrue);
    });

    test('matches spaced permission denied', () {
      expect(isPermissionDeniedException('Permission denied'), isTrue);
    });

    test('returns false for unrelated error', () {
      expect(isPermissionDeniedException('network timeout'), isFalse);
    });
  });

  group('isNotFoundException', () {
    test('matches hyphenated not found', () {
      expect(isNotFoundException('not-found'), isTrue);
    });

    test('matches spaced not found', () {
      expect(isNotFoundException('Not found'), isTrue);
    });

    test('returns false for unrelated error', () {
      expect(isNotFoundException('permission-denied'), isFalse);
    });
  });
}

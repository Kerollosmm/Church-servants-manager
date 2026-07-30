import 'package:church_management_system/core/utils/exception_matchers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isPermissionDeniedException', () {
    test('returns true for FirebaseException with permission-denied code', () {
      final exc = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      expect(isPermissionDeniedException(exc), isTrue);
    });

    test('returns false for FirebaseException with other code', () {
      final exc = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
      );
      expect(isPermissionDeniedException(exc), isFalse);
    });

    test(
      'returns true for Exception or String containing permission-denied substring',
      () {
        expect(
          isPermissionDeniedException(
            Exception('CloudFirestoreError: PERMISSION-DENIED occurred'),
          ),
          isTrue,
        );
        expect(
          isPermissionDeniedException(
            'User does not have permission denied error',
          ),
          isTrue,
        );
      },
    );

    test('returns false for unrelated errors', () {
      expect(
        isPermissionDeniedException(Exception('Network timeout')),
        isFalse,
      );
      expect(isPermissionDeniedException('Unknown error'), isFalse);
    });
  });

  group('isNotFoundException', () {
    test('returns true for FirebaseException with not-found code', () {
      final exc = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
      );
      expect(isNotFoundException(exc), isTrue);
    });

    test('returns false for FirebaseException with other code', () {
      final exc = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      expect(isNotFoundException(exc), isFalse);
    });

    test(
      'returns true for Exception or String containing not-found / not found substring',
      () {
        expect(
          isNotFoundException(Exception('Document NOT-FOUND in collection')),
          isTrue,
        );
        expect(
          isNotFoundException('Requested resource was not found on server'),
          isTrue,
        );
      },
    );

    test('returns false for unrelated errors', () {
      expect(isNotFoundException(Exception('Server error 500')), isFalse);
      expect(isNotFoundException('Internal server error'), isFalse);
    });
  });
}

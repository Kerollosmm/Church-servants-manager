import 'dart:async';
import 'dart:io';

import 'package:church_management_system/core/utils/sync_error_classifier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncErrorClassifier unit tests', () {
    group('FirebaseException', () {
      test('returns true for transient/retriable Firestore error codes', () {
        const retriableCodes = [
          'unavailable',
          'deadline-exceeded',
          'aborted',
          'internal',
          'resource-exhausted',
        ];

        for (final code in retriableCodes) {
          final error = FirebaseException(
            plugin: 'cloud_firestore',
            code: code,
          );
          expect(
            SyncErrorClassifier.isRetriable(error),
            isTrue,
            reason: 'Expected error code "$code" to be retriable',
          );
        }
      });

      test('returns false for permanent Firestore error codes', () {
        const nonRetriableCodes = [
          'permission-denied',
          'not-found',
          'already-exists',
          'unauthenticated',
          'invalid-argument',
        ];

        for (final code in nonRetriableCodes) {
          final error = FirebaseException(
            plugin: 'cloud_firestore',
            code: code,
          );
          expect(
            SyncErrorClassifier.isRetriable(error),
            isFalse,
            reason: 'Expected error code "$code" to not be retriable',
          );
        }
      });
    });

    group('Typed Network / System Exceptions', () {
      test('returns true for SocketException', () {
        expect(
          SyncErrorClassifier.isRetriable(
            const SocketException('Failed host lookup'),
          ),
          isTrue,
        );
      });

      test('returns true for TimeoutException', () {
        expect(
          SyncErrorClassifier.isRetriable(
            TimeoutException('Operation timed out'),
          ),
          isTrue,
        );
      });

      test('returns true for HttpException', () {
        expect(
          SyncErrorClassifier.isRetriable(
            const HttpException('503 Service Unavailable'),
          ),
          isTrue,
        );
      });
    });

    group('Error String Matching Fallback', () {
      test(
        'returns true for exceptions/strings containing network error keywords',
        () {
          expect(
            SyncErrorClassifier.isRetriable(
              Exception('Custom SocketException: OS Error'),
            ),
            isTrue,
          );
          expect(
            SyncErrorClassifier.isRetriable('Request timeout after 30 seconds'),
            isTrue,
          );
          expect(
            SyncErrorClassifier.isRetriable('Database connection failed'),
            isTrue,
          );
          expect(
            SyncErrorClassifier.isRetriable('Mobile network unreachable'),
            isTrue,
          );
          expect(
            SyncErrorClassifier.isRetriable(
              'Backend service is currently unavailable',
            ),
            isTrue,
          );
        },
      );

      test('returns false for non-retriable generic exceptions or strings', () {
        expect(
          SyncErrorClassifier.isRetriable(
            Exception('FormatException: Invalid JSON'),
          ),
          isFalse,
        );
        expect(
          SyncErrorClassifier.isRetriable('NullReferenceException'),
          isFalse,
        );
        expect(
          SyncErrorClassifier.isRetriable(
            StateError('Invalid state transition'),
          ),
          isFalse,
        );
      });
    });
  });
}

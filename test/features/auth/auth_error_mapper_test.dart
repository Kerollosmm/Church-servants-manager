import 'package:church_managment_system/features/auth/data/utils/auth_error_mapper.dart';
import 'package:church_managment_system/features/auth/domain/failures/auth_exceptions.dart';
import 'package:church_managment_system/features/auth/domain/failures/auth_failures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthErrorMapper', () {
    test('should map user-not-found to UserNotFoundFailure', () {
      final exception = FirebaseAuthException(code: 'user-not-found');
      final failure = AuthErrorMapper.mapException(exception);
      expect(failure, isA<UserNotFoundFailure>());
    });

    test('should map wrong-password to WrongPasswordFailure', () {
      final exception = FirebaseAuthException(code: 'wrong-password');
      final failure = AuthErrorMapper.mapException(exception);
      expect(failure, isA<WrongPasswordFailure>());
    });

    test('should map email-already-in-use to EmailAlreadyInUseFailure', () {
      final exception = FirebaseAuthException(code: 'email-already-in-use');
      final failure = AuthErrorMapper.mapException(exception);
      expect(failure, isA<EmailAlreadyInUseFailure>());
    });

    test('should map weak-password to WeakPasswordFailure', () {
      final exception = FirebaseAuthException(code: 'weak-password');
      final failure = AuthErrorMapper.mapException(exception);
      expect(failure, isA<WeakPasswordFailure>());
    });

    test('should map invalid-email to InvalidEmailFailure', () {
      final exception = FirebaseAuthException(code: 'invalid-email');
      final failure = AuthErrorMapper.mapException(exception);
      expect(failure, isA<InvalidEmailFailure>());
    });

    test('should map unknown code to GenericAuthFailure', () {
      final exception = FirebaseAuthException(code: 'unknown-code');
      final failure = AuthErrorMapper.mapException(exception);
      expect(failure, isA<GenericAuthFailure>());
    });

    test('should map non-Firebase exception to GenericAuthFailure', () {
      final exception = Exception('Something else');
      final failure = AuthErrorMapper.mapException(exception);
      expect(failure, isA<GenericAuthFailure>());
    });

    test('should map UserNotFoundAuthException to UserNotFoundFailure', () {
      final exception = UserNotFoundAuthException();
      final failure = AuthErrorMapper.mapException(exception);
      expect(failure, isA<UserNotFoundFailure>());
    });

    test('should map GenericAuthException with message to GenericAuthFailure', () {
      const message = 'Custom error';
      final exception = const GenericAuthException(message);
      final failure = AuthErrorMapper.mapException(exception);
      expect(failure, isA<GenericAuthFailure>());
      expect(failure.message, contains(message));
    });
  });
}

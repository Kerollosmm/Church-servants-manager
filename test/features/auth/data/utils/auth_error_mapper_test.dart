import 'package:church_management_system/features/auth/data/utils/auth_error_mapper.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_exceptions.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_failures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthErrorMapper unit tests', () {
    group('FirebaseAuthException mapping', () {
      test('maps user-not-found to UserNotFoundFailure', () {
        final e = FirebaseAuthException(code: 'user-not-found');
        expect(
          AuthErrorMapper.mapException(e),
          equals(const UserNotFoundFailure()),
        );
      });

      test(
        'maps wrong-password, invalid-credential, and INVALID_LOGIN_CREDENTIALS to WrongPasswordFailure',
        () {
          expect(
            AuthErrorMapper.mapException(
              FirebaseAuthException(code: 'wrong-password'),
            ),
            equals(const WrongPasswordFailure()),
          );
          expect(
            AuthErrorMapper.mapException(
              FirebaseAuthException(code: 'invalid-credential'),
            ),
            equals(const WrongPasswordFailure()),
          );
          expect(
            AuthErrorMapper.mapException(
              FirebaseAuthException(code: 'INVALID_LOGIN_CREDENTIALS'),
            ),
            equals(const WrongPasswordFailure()),
          );
        },
      );

      test('maps email-already-in-use to EmailAlreadyInUseFailure', () {
        final e = FirebaseAuthException(code: 'email-already-in-use');
        expect(
          AuthErrorMapper.mapException(e),
          equals(const EmailAlreadyInUseFailure()),
        );
      });

      test('maps weak-password to WeakPasswordFailure', () {
        final e = FirebaseAuthException(code: 'weak-password');
        expect(
          AuthErrorMapper.mapException(e),
          equals(const WeakPasswordFailure()),
        );
      });

      test('maps invalid-email to InvalidEmailFailure', () {
        final e = FirebaseAuthException(code: 'invalid-email');
        expect(
          AuthErrorMapper.mapException(e),
          equals(const InvalidEmailFailure()),
        );
      });

      test('maps user-disabled to GenericAuthFailure with custom message', () {
        final e = FirebaseAuthException(code: 'user-disabled');
        final failure = AuthErrorMapper.mapException(e);
        expect(failure, isA<GenericAuthFailure>());
        expect(
          (failure as GenericAuthFailure).message,
          contains('تم إيقاف هذا الحساب'),
        );
      });

      test(
        'maps too-many-requests to GenericAuthFailure with throttling message',
        () {
          final e = FirebaseAuthException(code: 'too-many-requests');
          final failure = AuthErrorMapper.mapException(e);
          expect(failure, isA<GenericAuthFailure>());
          expect(
            (failure as GenericAuthFailure).message,
            contains('لقد حاولت عدة مرات'),
          );
        },
      );

      test(
        'maps unhandled FirebaseAuthException code using message or code',
        () {
          final eWithMessage = FirebaseAuthException(
            code: 'custom-error',
            message: 'Custom message',
          );
          final failureWithMessage = AuthErrorMapper.mapException(eWithMessage);
          expect(
            (failureWithMessage as GenericAuthFailure).message,
            equals('Custom message'),
          );

          final eWithoutMessage = FirebaseAuthException(code: 'unknown-code');
          final failureWithoutMessage = AuthErrorMapper.mapException(
            eWithoutMessage,
          );
          expect(
            (failureWithoutMessage as GenericAuthFailure).message,
            equals('unknown-code'),
          );
        },
      );
    });

    group('Custom AuthException mapping', () {
      test('maps UserNotFoundAuthException', () {
        expect(
          AuthErrorMapper.mapException(UserNotFoundAuthException()),
          equals(const UserNotFoundFailure()),
        );
      });

      test('maps WrongPasswordAuthException', () {
        expect(
          AuthErrorMapper.mapException(WrongPasswordAuthException()),
          equals(const WrongPasswordFailure()),
        );
      });

      test('maps WeakPasswordAuthException', () {
        expect(
          AuthErrorMapper.mapException(WeakPasswordAuthException()),
          equals(const WeakPasswordFailure()),
        );
      });

      test('maps EmailAlreadyInUseAuthException', () {
        expect(
          AuthErrorMapper.mapException(EmailAlreadyInUseAuthException()),
          equals(const EmailAlreadyInUseFailure()),
        );
      });

      test('maps InvalidEmailAuthException', () {
        expect(
          AuthErrorMapper.mapException(InvalidEmailAuthException()),
          equals(const InvalidEmailFailure()),
        );
      });

      test('maps EmailNotVerifiedAuthException', () {
        expect(
          AuthErrorMapper.mapException(EmailNotVerifiedAuthException()),
          equals(const EmailNotVerifiedFailure()),
        );
      });

      test('maps ArchivedAccountAuthException', () {
        final failure = AuthErrorMapper.mapException(
          const ArchivedAccountAuthException('Account archived'),
        );
        expect(failure, isA<ArchivedAccountFailure>());
        expect(
          (failure as ArchivedAccountFailure).message,
          equals('Account archived'),
        );
      });

      test('maps UserNotLoggedInAuthException', () {
        expect(
          AuthErrorMapper.mapException(UserNotLoggedInAuthException()),
          equals(const UserNotLoggedInFailure()),
        );
      });

      test('maps PasswordResetAuthException', () {
        final failure = AuthErrorMapper.mapException(
          const PasswordResetAuthException('Reset error'),
        );
        expect(failure, isA<PasswordResetFailure>());
        expect(
          (failure as PasswordResetFailure).message,
          equals('Reset error'),
        );
      });

      test('maps GenericAuthException', () {
        final failure = AuthErrorMapper.mapException(
          const GenericAuthException('Generic error'),
        );
        expect(failure, isA<GenericAuthFailure>());
        expect(
          (failure as GenericAuthFailure).message,
          equals('Generic error'),
        );
      });
    });

    group('Direct AuthFailure and unknown error mapping', () {
      test(
        'returns AuthFailure directly if passed an AuthFailure instance',
        () {
          const failure = EmailAlreadyInUseFailure();
          expect(AuthErrorMapper.mapException(failure), equals(failure));
        },
      );

      test('returns default GenericAuthFailure for non-auth errors', () {
        expect(
          AuthErrorMapper.mapException(Exception('Random system failure')),
          equals(const GenericAuthFailure()),
        );
        expect(
          AuthErrorMapper.mapException('Unknown error string'),
          equals(const GenericAuthFailure()),
        );
      });
    });
  });
}

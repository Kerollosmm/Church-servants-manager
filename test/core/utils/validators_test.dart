import 'package:church_managment_system/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.validateEmail', () {
    test('returns error when empty', () {
      expect(Validators.validateEmail(''), 'Email is required');
      expect(Validators.validateEmail(null), 'Email is required');
    });

    test('returns error when invalid', () {
      expect(
        Validators.validateEmail('invalid-email'),
        'Enter a valid email address',
      );
    });

    test('returns null when valid', () {
      expect(Validators.validateEmail('user@example.com'), isNull);
    });
  });

  group('Validators.validatePassword', () {
    test('returns error when empty', () {
      expect(Validators.validatePassword(''), 'Password is required');
      expect(Validators.validatePassword(null), 'Password is required');
    });

    test('returns error when too short', () {
      expect(
        Validators.validatePassword('12345'),
        'Password must be at least 6 characters',
      );
    });

    test('returns null when valid', () {
      expect(Validators.validatePassword('123456'), isNull);
    });
  });

  group('Validators.validateName', () {
    test('returns error when empty', () {
      expect(Validators.validateName(''), 'Name is required');
      expect(Validators.validateName(null), 'Name is required');
    });

    test('returns error when too short after trim', () {
      expect(
        Validators.validateName(' a '),
        'Name must be at least 2 characters',
      );
    });

    test('returns null when valid', () {
      expect(Validators.validateName('John'), isNull);
    });
  });

  group('Validators.validatePhone', () {
    test('returns error when empty', () {
      expect(Validators.validatePhone(''), 'Phone number is required');
      expect(Validators.validatePhone(null), 'Phone number is required');
    });

    test('returns error when not 11 digits', () {
      expect(
        Validators.validatePhone('01234'),
        'Enter a valid 11-digit phone number',
      );
      expect(
        Validators.validatePhone('0123456789a'),
        'Enter a valid 11-digit phone number',
      );
    });

    test('returns null when valid', () {
      expect(Validators.validatePhone('01234567890'), isNull);
    });
  });
}

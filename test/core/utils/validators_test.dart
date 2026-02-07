import 'package:church_managment_system/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators', () {
    group('Email Validator', () {
      test('should return error if email is empty', () {
        expect(Validators.validateEmail(''), 'Email is required');
      });

      test('should return error if email is invalid', () {
        expect(Validators.validateEmail('invalid-email'), 'Enter a valid email address');
        expect(Validators.validateEmail('test@'), 'Enter a valid email address');
        expect(Validators.validateEmail('@example.com'), 'Enter a valid email address');
      });

      test('should return null if email is valid', () {
        expect(Validators.validateEmail('test@example.com'), null);
      });
    });

    group('Password Validator', () {
      test('should return error if password is empty', () {
        expect(Validators.validatePassword(''), 'Password is required');
      });

      test('should return error if password is too short', () {
        expect(Validators.validatePassword('12345'), 'Password must be at least 6 characters');
      });

      test('should return null if password is valid', () {
        expect(Validators.validatePassword('123456'), null);
      });
    });

    group('Name Validator', () {
      test('should return error if name is empty', () {
        expect(Validators.validateName(''), 'Name is required');
      });

      test('should return error if name is too short', () {
        expect(Validators.validateName('A'), 'Name must be at least 2 characters');
      });

      test('should return null if name is valid', () {
        expect(Validators.validateName('John Doe'), null);
      });
    });

    group('Phone Validator', () {
      test('should return error if phone is empty', () {
        expect(Validators.validatePhone(''), 'Phone number is required');
      });

      test('should return error if phone is invalid', () {
        expect(Validators.validatePhone('123'), 'Enter a valid 11-digit phone number');
        expect(Validators.validatePhone('abcdefghijk'), 'Enter a valid 11-digit phone number');
      });

      test('should return null if phone is valid', () {
        expect(Validators.validatePhone('01234567890'), null);
      });
    });
  });
}

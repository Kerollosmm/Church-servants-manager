import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/utils/json_converters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestoreTimestampConverter unit tests', () {
    const converter = FirestoreTimestampConverter();

    group('fromJson', () {
      test('returns null when json is null', () {
        expect(converter.fromJson(null), isNull);
      });

      test('returns DateTime directly when json is a DateTime', () {
        final now = DateTime.now();
        expect(converter.fromJson(now), equals(now));
      });

      test('converts Timestamp to DateTime', () {
        final timestamp = Timestamp.fromDate(DateTime(2026, 7, 30, 10));
        expect(converter.fromJson(timestamp), equals(timestamp.toDate()));
      });

      test('converts String ISO8601 to DateTime', () {
        final iso = '2026-07-30T10:00:00.000Z';
        expect(converter.fromJson(iso), equals(DateTime.parse(iso)));
      });

      test('converts int milliseconds to DateTime', () {
        final millis = 1700000000000;
        expect(
          converter.fromJson(millis),
          equals(DateTime.fromMillisecondsSinceEpoch(millis)),
        );
      });

      test('returns null for unsupported data types', () {
        expect(converter.fromJson(123.45), isNull);
        expect(converter.fromJson(true), isNull);
      });
    });

    group('toJson', () {
      test('returns null when date is null', () {
        expect(converter.toJson(null), isNull);
      });

      test('converts DateTime to Timestamp', () {
        final date = DateTime(2026, 7, 30, 10);
        final result = converter.toJson(date);
        expect(result, isA<Timestamp>());
        expect((result as Timestamp).toDate(), equals(date));
      });
    });
  });

  group('RequiredFirestoreTimestampConverter unit tests', () {
    const converter = RequiredFirestoreTimestampConverter();

    group('fromJson', () {
      test('returns epoch zero DateTime when json is null or invalid', () {
        expect(
          converter.fromJson(null),
          equals(DateTime.fromMillisecondsSinceEpoch(0)),
        );
        expect(
          converter.fromJson('invalid-date'),
          equals(DateTime.fromMillisecondsSinceEpoch(0)),
        );
      });

      test('converts valid Timestamp or DateTime', () {
        final date = DateTime(2026, 7, 30, 12);
        final timestamp = Timestamp.fromDate(date);
        expect(converter.fromJson(timestamp), equals(date));
        expect(converter.fromJson(date), equals(date));
      });
    });

    group('toJson', () {
      test('converts non-null DateTime to Timestamp', () {
        final date = DateTime(2026, 7, 30, 12);
        final result = converter.toJson(date);
        expect(result, isA<Timestamp>());
        expect((result as Timestamp).toDate(), equals(date));
      });
    });
  });

  group('UserRoleJsonConverter unit tests', () {
    const converter = UserRoleJsonConverter();

    group('fromJson', () {
      test('returns UserRole.servant when json is null or unknown', () {
        expect(converter.fromJson(null), equals(UserRole.servant));
        expect(converter.fromJson('unknown'), equals(UserRole.servant));
      });

      test('converts string roles correctly regardless of case', () {
        expect(converter.fromJson('admin'), equals(UserRole.admin));
        expect(converter.fromJson('ADMIN'), equals(UserRole.admin));

        expect(converter.fromJson('student'), equals(UserRole.student));
        expect(converter.fromJson('Student'), equals(UserRole.student));

        expect(converter.fromJson('servant'), equals(UserRole.servant));
        expect(converter.fromJson('SERVANT'), equals(UserRole.servant));
      });
    });

    group('toJson', () {
      test('converts UserRole enum to role name string', () {
        expect(converter.toJson(UserRole.admin), equals('admin'));
        expect(converter.toJson(UserRole.student), equals('student'));
        expect(converter.toJson(UserRole.servant), equals('servant'));
      });
    });
  });
}

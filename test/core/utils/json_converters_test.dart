import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/utils/json_converters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const converter = FirestoreTimestampConverter();

  group('FirestoreTimestampConverter.fromJson', () {
    test('returns null for null input', () {
      expect(converter.fromJson(null), isNull);
    });

    test('converts Timestamp to DateTime', () {
      final date = DateTime(2024, 1, 2, 3, 4, 5);
      final result = converter.fromJson(Timestamp.fromDate(date));
      expect(result, date);
    });

    test('parses ISO string', () {
      final result = converter.fromJson('2024-01-02T03:04:05.000Z');
      expect(result, DateTime.parse('2024-01-02T03:04:05.000Z'));
    });

    test('converts milliseconds epoch', () {
      final result = converter.fromJson(1704164645000);
      expect(result, DateTime.fromMillisecondsSinceEpoch(1704164645000));
    });
  });

  group('FirestoreTimestampConverter.toJson', () {
    test('returns null for null date', () {
      expect(converter.toJson(null), isNull);
    });

    test('converts DateTime to Timestamp', () {
      final date = DateTime(2024, 1, 2, 3, 4, 5);
      final json = converter.toJson(date);
      expect(json, isA<Timestamp>());
      expect((json as Timestamp).toDate(), date);
    });
  });

  group('UserRoleJsonConverter', () {
    const converter = UserRoleJsonConverter();

    test('fromJson maps known values and defaults servant', () {
      expect(converter.fromJson('admin'), UserRole.admin);
      expect(converter.fromJson('student'), UserRole.student);
      expect(converter.fromJson('servant'), UserRole.servant);
      expect(converter.fromJson('UNKNOWN'), UserRole.servant);
      expect(converter.fromJson(null), UserRole.servant);
    });

    test('toJson serializes enum name', () {
      expect(converter.toJson(UserRole.admin), 'admin');
      expect(converter.toJson(UserRole.student), 'student');
      expect(converter.toJson(UserRole.servant), 'servant');
    });
  });
}

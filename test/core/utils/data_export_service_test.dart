import 'package:church_management_system/core/utils/data_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DataExportService service;

  setUp(() {
    service = DataExportService();
  });

  group('generateCsv', () {
    test('returns CSV string with headers and data rows', () {
      final headers = ['Name', 'Age', 'Grade'];
      final rows = [
        ['Mina', 15, 'Year 1'],
        ['Andrew', 16, 'Year 2'],
      ];

      final csv = service.generateCsv(headers, rows);
      final lines = csv.trim().split(RegExp(r'\r?\n'));

      expect(lines.length, 3);
      expect(lines[0], 'Name,Age,Grade');
      expect(lines[1], 'Mina,15,Year 1');
      expect(lines[2], 'Andrew,16,Year 2');
    });

    test('returns only headers when rows are empty', () {
      final headers = ['Name', 'Age'];
      final csv = service.generateCsv(headers, []);
      expect(csv.trim(), 'Name,Age');
    });

    test('handles Arabic text correctly', () {
      final headers = ['الاسم', 'الفريق'];
      final rows = [
        ['مينا', 'Team A'],
        ['أندرو', 'Team B'],
      ];

      final csv = service.generateCsv(headers, rows);
      expect(csv.trim().contains('مينا'), isTrue);
      expect(csv.trim().contains('أندرو'), isTrue);
    });

    test('escapes commas inside field values', () {
      final headers = ['Name', 'Notes'];
      final rows = [
        ['Mina', 'Present, on time'],
      ];

      final csv = service.generateCsv(headers, rows);
      expect(csv.trim().contains('"Present, on time"'), isTrue);
    });

    test('handles single row of data', () {
      final headers = ['ID'];
      final rows = [
        ['1'],
      ];

      final csv = service.generateCsv(headers, rows);
      expect(csv.trim().split(RegExp(r'\r?\n')).length, 2);
    });

    test('handles numeric and mixed data types', () {
      final headers = ['Name', 'Score', 'Passed'];
      final rows = [
        ['Mina', 95.5, true],
      ];

      final csv = service.generateCsv(headers, rows);
      expect(csv.trim().split(RegExp(r'\r?\n')).length, 2);
    });
  });
}

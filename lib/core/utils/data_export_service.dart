import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class DataExportService {
  /// Generates a CSV string from a list of rows.
  String generateCsv(List<String> headers, List<List<dynamic>> rows) {
    final List<List<dynamic>> csvData = [headers, ...rows];
    return Csv().encode(csvData);
  }

  /// Exports and shares a CSV file.
  Future<void> exportCsv({
    required String fileName,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    final csvString = generateCsv(headers, rows);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName.csv');
    await file.writeAsString(csvString);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'تصدير بيانات المخدومين'),
    );
  }

  /// Exports and shares a PDF file.
  Future<void> exportPdf({
    required String title,
    required String fileName,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    final pdf = pw.Document();

    final fontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);
    final theme = pw.ThemeData.withFont(base: ttf);

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text(title)),
          pw.TableHelper.fromTextArray(headers: headers, data: rows),
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName.pdf');
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'تصدير تقرير المخدومين'),
    );
  }
}

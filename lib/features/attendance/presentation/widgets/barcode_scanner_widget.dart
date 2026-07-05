import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/features/student/data/datasources/student_local_datasource.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Barcode scanner widget that queries local students_box cache,
/// triggers vibration feedback, and invokes the scanned callback.
class BarcodeScannerWidget extends StatelessWidget {
  final String teamId;
  final String sessionId;
  final void Function(String studentId) onStudentScanned;

  const BarcodeScannerWidget({
    super.key,
    required this.teamId,
    required this.sessionId,
    required this.onStudentScanned,
  });

  Future<void> _handleScan(String scannedCode, BuildContext context) async {
    // 1. Query local students_box by barcode/docID
    final studentDatasource = getIt<StudentLocalDatasource>();
    final student = await studentDatasource.getStudent(scannedCode);

    if (!context.mounted) return;

    if (student != null) {
      // 2. Vibration feedback
      await HapticFeedback.mediumImpact();
      // 3. Trigger mark callback
      onStudentScanned(student.docID);
    } else {
      await HapticFeedback.heavyImpact(); // Error feedback
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الطالب غير موجود في القائمة المحلية'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مسح الباركود')),
      body: MobileScanner(
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final rawValue = barcodes.first.rawValue;
            if (rawValue != null && rawValue.isNotEmpty) {
              _handleScan(rawValue, context);
            }
          }
        },
      ),
    );
  }
}

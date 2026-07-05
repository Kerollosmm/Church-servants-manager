import 'dart:io';
import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/core/utils/data_export_service.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_session.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportAttendanceButton extends StatefulWidget {
  final String teamId;
  final String teamName;
  final List<AttendanceSession> sessions;

  const ExportAttendanceButton({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.sessions,
  });

  @override
  State<ExportAttendanceButton> createState() => _ExportAttendanceButtonState();
}

class _ExportAttendanceButtonState extends State<ExportAttendanceButton> {
  bool _isExporting = false;

  Future<void> _exportReport() async {
    if (widget.sessions.isEmpty) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final firestore = getIt<FirebaseFirestore>();
      final studentRepo = getIt<IStudentRepository>();

      // 1. Fetch students in the team
      final students = await studentRepo.getStudentsByClass(widget.teamId);

      // 2. Fetch marks for each session
      final Map<String, List<String>> studentAttendanceMap = {};
      final closedSessions = widget.sessions.where((s) => s.isClosed).toList();

      for (final session in closedSessions) {
        final marksSnapshot = await firestore
            .collection('AttendanceSessions')
            .doc(session.id)
            .collection('records')
            .get();

        final Map<String, String> sessionMarks = {};
        for (final doc in marksSnapshot.docs) {
          final data = doc.data();
          final studentId = data['studentId'] as String?;
          final status = data['status'] as String?;
          if (studentId != null && status != null) {
            sessionMarks[studentId] = status == 'present'
                ? 'حاضر'
                : (status == 'late' ? 'متأخر' : 'غائب');
          }
        }

        // Populate statuses for each student
        for (final student in students) {
          final status = sessionMarks[student.docID] ?? 'غائب';
          studentAttendanceMap.putIfAbsent(student.docID, () => []).add(status);
        }
      }

      // 3. Generate and export CSV
      final exportService = DataExportService();
      final List<String> headers = [
        'اسم الطالب',
        ...closedSessions.map(
          (s) => s.title ?? s.startsAt.toIso8601String().split('T')[0],
        ),
      ];
      final List<List<Object?>> rows = [];
      for (final student in students) {
        final attendanceList = studentAttendanceMap[student.docID] ?? [];
        rows.add([student.name, ...attendanceList]);
      }
      final csvString = exportService.generateCsv(headers, rows);

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/تقرير_حضور_${widget.teamName}.csv');
      await file.writeAsString(csvString);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'تقرير حضور فريق ${widget.teamName}');

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تصدير التقرير: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isExporting) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.download),
      tooltip: 'تصدير كشف الحضور',
      onPressed: widget.sessions.isEmpty ? null : _exportReport,
    );
  }
}

# CSMS Tools

This directory contains standalone scripts and utilities for managing the Church Servants Management System (CSMS) backend.

## Student Attendance History Backfill

The `backfill_student_attendance_sessions.dart` script migrates historical attendance session records. It populates the new subcollection `students/{studentId}/attendanceSessions/{sessionId}` from existing closed sessions and their marks.

### How to Run

1. Ensure the Dart SDK is installed.
2. Run the script:
   ```bash
   dart tools/backfill_student_attendance_sessions.dart
   ```

class FirestoreCollections {
  // NOTE: Update these names if your Firestore collections use different casing.
  static const users = 'Users';
  static const students = 'Students';
  static const classes = 'Classes';
  static const attendanceSessions = 'attendance_sessions';
  static const attendanceMarks = 'marks';
  static const attendanceAuditEvents = 'audit_events';
  // FIX [015] Read-model collections for pre-aggregated attendance data (scalability).
  static const attendanceHistory = 'attendance_history';
  static const attendanceStats = 'attendance_stats';
  // Admin audit log collection written by Cloud Functions.
  static const auditLogs = 'audit_logs';
  // Servants are stored in Users collection with role == 'servant'
}

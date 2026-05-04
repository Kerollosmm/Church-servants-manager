class FirestoreFields {
  // Shared Fields
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
  static const isArchived = 'isArchived';

  // AI & Aggregation Fields
  static const attendanceSummary = 'attendanceSummary';
  static const groupAttendanceSummary = 'groupAttendanceSummary';

  // Student Specific
  static const classId = 'classId';
  static const studentUid = 'uid';

  // Session Specific
  static const isClosed = 'isClosed';
  static const startsAt = 'startsAt';
  static const endsAt = 'endsAt';
}

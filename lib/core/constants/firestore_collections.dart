class FirestoreCollections {
  // NOTE: Update these names if your Firestore collections use different casing.
  static const users = 'Users'; // FIX [009]: align Firestore path casing
  static const students = 'Students'; // FIX [009]: align Firestore path casing
  static const classes = 'Classes'; // FIX [009]: align Firestore path casing
  static const attendanceSessions = 'attendance_sessions';
  static const attendanceMarks = 'Marks';
  // Servants are stored in users collection with role == 'servant'
}

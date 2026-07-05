// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Church Servants Management System';

  @override
  String get attendanceHistory => 'Attendance History';

  @override
  String get takeAttendance => 'Take Attendance';

  @override
  String get createSession => 'Create Attendance Session';

  @override
  String get openSession => 'Open Session';

  @override
  String get closedSession => 'Closed Session';

  @override
  String get openSessionButton => 'Open Session';

  @override
  String get closeSessionButton => 'Close';

  @override
  String get attendanceSavedOffline =>
      'Attendance saved locally and will sync when online';

  @override
  String get studentNotInRoster => 'Student is not in this session\'s roster';

  @override
  String get studentNotFoundLocal => 'Student not found in local data';

  @override
  String get exportReportFailed => 'Failed to export report';

  @override
  String get present => 'Present';

  @override
  String get late => 'Late';

  @override
  String get absent => 'Absent';

  @override
  String get unmarked => 'Unmarked';

  @override
  String get scanBarcode => 'Scan Barcode';

  @override
  String get localDataBanner =>
      'Displaying locally cached data. May not be up to date.';

  @override
  String get gradeEntry => 'Grade Entry';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading...';
}

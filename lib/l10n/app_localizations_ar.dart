// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'نظام إدارة خدمة الكنيسة';

  @override
  String get attendanceHistory => 'سجل الحضور';

  @override
  String get takeAttendance => 'تسجيل الحضور';

  @override
  String get createSession => 'إنشاء جلسة حضور';

  @override
  String get openSession => 'جلسة مفتوحة';

  @override
  String get closedSession => 'جلسة مغلقة';

  @override
  String get openSessionButton => 'فتح الجلسة';

  @override
  String get closeSessionButton => 'إغلاق';

  @override
  String get attendanceSavedOffline =>
      'يتم حفظ الحضور محلياً وسيتم المزامنة لاحقاً';

  @override
  String get studentNotInRoster => 'الطالب ليس في قائمة هذه الجلسة';

  @override
  String get studentNotFoundLocal => 'الطالب غير موجود في القائمة المحلية';

  @override
  String get exportReportFailed => 'فشل تصدير التقرير';

  @override
  String get present => 'حاضر';

  @override
  String get late => 'متأخر';

  @override
  String get absent => 'غائب';

  @override
  String get unmarked => 'غير مسجل';

  @override
  String get scanBarcode => 'مسح الباركود';

  @override
  String get localDataBanner =>
      'عرض البيانات المخزنة محلياً. قد لا تكون محدثة.';

  @override
  String get gradeEntry => 'رصد الدرجات';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get loading => 'جاري التحميل...';
}

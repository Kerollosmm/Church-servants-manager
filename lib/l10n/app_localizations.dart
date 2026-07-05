import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'نظام إدارة خدمة الكنيسة'**
  String get appTitle;

  /// No description provided for @attendanceHistory.
  ///
  /// In ar, this message translates to:
  /// **'سجل الحضور'**
  String get attendanceHistory;

  /// No description provided for @takeAttendance.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الحضور'**
  String get takeAttendance;

  /// No description provided for @createSession.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء جلسة حضور'**
  String get createSession;

  /// No description provided for @openSession.
  ///
  /// In ar, this message translates to:
  /// **'جلسة مفتوحة'**
  String get openSession;

  /// No description provided for @closedSession.
  ///
  /// In ar, this message translates to:
  /// **'جلسة مغلقة'**
  String get closedSession;

  /// No description provided for @openSessionButton.
  ///
  /// In ar, this message translates to:
  /// **'فتح الجلسة'**
  String get openSessionButton;

  /// No description provided for @closeSessionButton.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get closeSessionButton;

  /// No description provided for @attendanceSavedOffline.
  ///
  /// In ar, this message translates to:
  /// **'يتم حفظ الحضور محلياً وسيتم المزامنة لاحقاً'**
  String get attendanceSavedOffline;

  /// No description provided for @studentNotInRoster.
  ///
  /// In ar, this message translates to:
  /// **'الطالب ليس في قائمة هذه الجلسة'**
  String get studentNotInRoster;

  /// No description provided for @studentNotFoundLocal.
  ///
  /// In ar, this message translates to:
  /// **'الطالب غير موجود في القائمة المحلية'**
  String get studentNotFoundLocal;

  /// No description provided for @exportReportFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل تصدير التقرير'**
  String get exportReportFailed;

  /// No description provided for @present.
  ///
  /// In ar, this message translates to:
  /// **'حاضر'**
  String get present;

  /// No description provided for @late.
  ///
  /// In ar, this message translates to:
  /// **'متأخر'**
  String get late;

  /// No description provided for @absent.
  ///
  /// In ar, this message translates to:
  /// **'غائب'**
  String get absent;

  /// No description provided for @unmarked.
  ///
  /// In ar, this message translates to:
  /// **'غير مسجل'**
  String get unmarked;

  /// No description provided for @scanBarcode.
  ///
  /// In ar, this message translates to:
  /// **'مسح الباركود'**
  String get scanBarcode;

  /// No description provided for @localDataBanner.
  ///
  /// In ar, this message translates to:
  /// **'عرض البيانات المخزنة محلياً. قد لا تكون محدثة.'**
  String get localDataBanner;

  /// No description provided for @gradeEntry.
  ///
  /// In ar, this message translates to:
  /// **'رصد الدرجات'**
  String get gradeEntry;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل...'**
  String get loading;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

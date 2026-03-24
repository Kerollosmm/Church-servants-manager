// FIX [007]: Consolidated English and Arabic validation logic into shared
// private helpers (_validate, _validateLength) to eliminate duplication and
// ensure both locales execute the same core pattern-check logic.
class Validators {
  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static final _phoneRegex = RegExp(r'^\d{11}$');

  static bool _isEmpty(String? value) => value == null || value.trim().isEmpty;

  /// Shared internal helper: checks required + pattern in one place.
  static String? _validate(
    String? value,
    String emptyMsg,
    String invalidMsg,
    bool Function(String) patternCheck,
  ) {
    if (_isEmpty(value)) return emptyMsg;
    if (!patternCheck(value!.trim())) return invalidMsg;
    return null;
  }

  /// Shared internal helper: checks required + minimum length in one place.
  static String? _validateLength(
    String? value,
    String emptyMsg,
    String tooShortMsg,
    int minLength,
  ) {
    if (_isEmpty(value)) return emptyMsg;
    if (value!.trim().length < minLength) return tooShortMsg;
    return null;
  }

  // ---- English validators ----

  static String? validateEmail(String? value) => _validate(
    value,
    'Email is required',
    'Enter a valid email address',
    _emailRegex.hasMatch,
  );

  static String? validatePassword(String? value) => _validateLength(
    value,
    'Password is required',
    'Password must be at least 6 characters',
    6,
  );

  static String? validateName(String? value) => _validateLength(
    value,
    'Name is required',
    'Name must be at least 2 characters',
    2,
  );

  static String? validatePhone(String? value) => _validate(
    value,
    'Phone number is required',
    'Enter a valid 11-digit phone number',
    _phoneRegex.hasMatch,
  );

  // ---- Arabic validators ----

  static String? validateRequiredArabic(
    String? value, {
    String fieldLabel = 'هذا الحقل',
  }) {
    if (_isEmpty(value)) return '$fieldLabel مطلوب';
    return null;
  }

  static String? validateEmailArabic(String? value) => _validate(
    value,
    'البريد الإلكتروني مطلوب',
    'أدخل بريدا إلكترونيا صحيحا',
    _emailRegex.hasMatch,
  );

  static String? validateOptionalEmailArabic(String? value) {
    if (_isEmpty(value)) return null;
    return validateEmailArabic(value);
  }

  static String? validatePasswordArabic(String? value) => _validateLength(
    value,
    'كلمة المرور مطلوبة',
    'يجب أن تكون كلمة المرور 6 أحرف على الأقل',
    6,
  );

  static String? validateNameArabic(String? value) => _validateLength(
    value,
    'الاسم مطلوب',
    'يجب أن يحتوي الاسم على حرفين على الأقل',
    2,
  );

  static String? validatePhoneArabic(String? value) => _validate(
    value,
    'رقم الهاتف مطلوب',
    'أدخل رقم هاتف صحيح مكون من 11 رقما',
    _phoneRegex.hasMatch,
  );

  static String? validateOptionalPhoneArabic(String? value) {
    if (_isEmpty(value)) return null;
    return validatePhoneArabic(value);
  }
}

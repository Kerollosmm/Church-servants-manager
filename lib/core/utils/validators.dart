class Validators {
  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static final _phoneRegex = RegExp(r'^\d{11}$');

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!_phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid 11-digit phone number';
    }
    return null;
  }

  static String? validateRequiredArabic(
    String? value, {
    String fieldLabel = 'هذا الحقل',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldLabel مطلوب';
    }
    return null;
  }

  static String? validateEmailArabic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'أدخل بريدا إلكترونيا صحيحا';
    }
    return null;
  }

  static String? validateOptionalEmailArabic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return validateEmailArabic(value);
  }

  static String? validatePasswordArabic(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 6) {
      return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
    }
    return null;
  }

  static String? validateNameArabic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الاسم مطلوب';
    }
    if (value.trim().length < 2) {
      return 'يجب أن يحتوي الاسم على حرفين على الأقل';
    }
    return null;
  }

  static String? validatePhoneArabic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'رقم الهاتف مطلوب';
    }
    if (!_phoneRegex.hasMatch(value.trim())) {
      return 'أدخل رقم هاتف صحيح مكون من 11 رقما';
    }
    return null;
  }

  static String? validateOptionalPhoneArabic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return validatePhoneArabic(value);
  }
}

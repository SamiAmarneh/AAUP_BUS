abstract final class PhoneNumberValidator {
  static final RegExp _phoneNumberRegex = RegExp(
    r'^(?:(?:(\+?972|\(\+?972\)|\+?\(972\))(?:\s|\.|-)?([1-9]\d?))|(0[23489]{1})|(0[57]{1}[0-9]))(?:\s|\.|-)?([^0\D]{1}\d{2}(?:\s|\.|-)?\d{4})$',
  );

  static String cleanPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[\s.\-]'), '');
  }

  static bool validatePhoneNumber(String phoneNumber) {
    final cleanedPhoneNumber = cleanPhoneNumber(phoneNumber);
    return _phoneNumberRegex.hasMatch(cleanedPhoneNumber);
  }

  static String normalizePhoneNumber(String phoneNumber) {
    final cleaned = cleanPhoneNumber(phoneNumber);
    final internationalMatch = RegExp(
      r'^(\+?972|\(\+?972\)|\+?\(972\))(.+)$',
    ).firstMatch(cleaned);

    if (internationalMatch != null) {
      final localPart = internationalMatch.group(2) ?? '';
      return '0$localPart';
    }

    return cleaned;
  }
}

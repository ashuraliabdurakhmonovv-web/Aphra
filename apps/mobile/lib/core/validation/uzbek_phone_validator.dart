abstract final class UzbekPhoneValidator {
  static final RegExp _digits = RegExp(r'^\d{9}$');

  static String normalize(String input) => input.replaceAll(RegExp(r'\D'), '');

  static bool isValid(String input) {
    final value = normalize(input);
    return _digits.hasMatch(value) && value.startsWith(RegExp(r'[3-9]'));
  }
}

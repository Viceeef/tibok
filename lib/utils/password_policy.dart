/// Shared rules for newly created and replacement passwords.
/// Existing credentials are still accepted by the login screen.
class PasswordPolicy {
  static const String requirements =
      'Use at least 8 characters, including a letter and a number.';

  static String? validate(String? password) {
    if (password == null ||
        password.runes.length < 8 ||
        !RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password)) {
      return requirements;
    }
    return null;
  }
}

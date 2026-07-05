class ValidationUtils {
  /// Validates password strength:
  /// - At least 8 characters long
  /// - Contains at least one uppercase letter
  /// - Contains at least one special character
  static bool isValidPassword(String password) {
    final passRegex = RegExp(r'^(?=.*[A-Z])(?=.*[\W_]).{8,}$');
    return passRegex.hasMatch(password);
  }

  /// Validates basic email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9-]+\.[a-zA-Z]+");
    return emailRegex.hasMatch(email);
  }
}

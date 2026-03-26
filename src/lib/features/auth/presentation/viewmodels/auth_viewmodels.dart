// viewmodels/auth_viewmodels.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_helper.dart';

// ==========================================
// BASE VIEWMODEL (Handles Loading, Validation & Errors)
// ==========================================
class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // --- FRONTEND VALIDATION HELPERS ---

  // Check valid email format using RegEx
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9-]+\.[a-zA-Z]+");
    return emailRegex.hasMatch(email);
  }

  // Check if password has at least 1 uppercase, 1 lowercase, 1 number, and 1 special character
  bool isStrongPassword(String password) {
    final passRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{6,}$');
    return passRegex.hasMatch(password);
  }

  // --- BACKEND ERROR TRANSLATOR ---
  // Vietnamese translator machine for Supabase exceptions
  String handleError(dynamic e) {
    if (e is! AuthException) {
      return 'Sever lỗi, vui lòng thử lại!';
    }

    final msg = e.message.toLowerCase();

    // Dictionary error map (Backend errors only, frontend catches the rest)
    final errorDictionary = {
      'already registered': 'Email này đã được đăng ký!',
      'already exists': 'Email này đã được đăng ký!',
      'invalid login credentials': 'Email hoặc mật khẩu không chính xác!',
      'rate limit': 'Bạn thao tác quá nhanh, vui lòng thử lại sau!',
      'over_email_send_rate_limit': 'Bạn thao tác quá nhanh, vui lòng thử lại sau!',
      'token has expired or is invalid': 'Mã OTP không hợp lệ hoặc đã hết hạn!',
    };

    for (final entry in errorDictionary.entries) {
      if (msg.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'Lỗi xác thực: ${e.message}';
  }
}

// Global AuthHelper instance for all ViewModels
final _authHelper = AuthHelper();

// ==========================================
// 1. LOGIN VIEWMODEL
// ==========================================
class LoginViewModel extends BaseViewModel {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool obscurePass = true;

  void togglePass() { obscurePass = !obscurePass; notifyListeners(); }

  Future<String?> login() async {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    // FRONTEND VALIDATION: Empty fields & Email format
    if (email.isEmpty || pass.isEmpty) {
      return 'Vui lòng nhập đầy đủ email và mật khẩu!';
    }
    if (!isValidEmail(email)) {
      return 'Định dạng email không hợp lệ!';
    }

    setLoading(true);
    try {
      final user = await _authHelper.login(email, pass);
      if (user != null) return null; // Success
      return 'Không thể lấy thông tin người dùng!';
    } catch (e) {
      return handleError(e); // Backend errors
    } finally {
      setLoading(false);
    }
  }
  // 1.1 LOGIN WITH GOOGLE
  Future<String?> loginWithGoogle() async {
    setLoading(true);
    try {
      final success = await _authHelper.loginWithGoogle();
      if (success) return null; // Thành công (thường Supabase sẽ tự văng ra web browser)
      return 'Lỗi khi mở cổng đăng nhập Google!';
    } catch (e) {
      return handleError(e);
    } finally {
      setLoading(false);
    }
  }

// 1.2 LOGIN WITH FACEBOOK

  Future<String?> loginWithFacebook() async {
    setLoading(true);
    try {
      final success = await _authHelper.loginWithFacebook();
      if (success) return null;
      return 'Lỗi khi mở cổng đăng nhập Facebook!';
    } catch (e) {
      return handleError(e);
    } finally {
      setLoading(false);
    }
  }
}


// ==========================================
// 2. REGISTER VIEWMODEL
// ==========================================
class RegisterViewModel extends BaseViewModel {
  final usernameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();
  bool obscurePass = true;

  void togglePass() { obscurePass = !obscurePass; notifyListeners(); }

  Future<String?> register() async {
    final username = usernameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;
    final confirmPass = confirmPassCtrl.text;

    // FRONTEND VALIDATION: Strict client-side checks
    if (username.isEmpty || email.isEmpty) {
      return 'Vui lòng điền đủ thông tin!';
    }
    if (!isValidEmail(email)) {
      return 'Định dạng email không hợp lệ!'; // Blocked at FE
    }
    if (pass.length < 8) {
      return 'Mật khẩu phải từ 8 ký tự trở lên!';
    }
    if (!isStrongPassword(pass)) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ hoa, thường, số và ký tự đặc biệt!'; // Blocked at FE
    }
    if (pass != confirmPass) {
      return 'Mật khẩu xác nhận không khớp!';
    }

    setLoading(true);
    try {
      final user = await _authHelper.register(email, pass, username);
      if (user != null) return null; // Success
      return 'Đăng ký thất bại, không có dữ liệu trả về!';
    } catch (e) {
      return handleError(e); // Backend errors (e.g., email already exists)
    } finally {
      setLoading(false);
    }
  }
}

// ==========================================
// 3. FORGOT PASSWORD VIEWMODEL (Step 1)
// ==========================================
class ForgotPassViewModel extends BaseViewModel {
  final emailCtrl = TextEditingController();

  // Static variable to temporarily hold email for OTP screen
  static String recoveryEmail = '';

  Future<String?> sendCode() async {
    final email = emailCtrl.text.trim();

    // FRONTEND VALIDATION
    if (email.isEmpty) return 'Vui lòng nhập email của bạn!';
    if (!isValidEmail(email)) return 'Định dạng email không hợp lệ!';

    setLoading(true);
    try {
      recoveryEmail = email;
      await _authHelper.sendPasswordReset(recoveryEmail);
      return null; // Success
    } catch (e) {
      return handleError(e);
    } finally {
      setLoading(false);
    }
  }
}

// ==========================================
// 4. OTP VERIFICATION VIEWMODEL (Step 2)
// ==========================================
class OtpViewModel extends BaseViewModel {
  List<String> digits = List.filled(6, "");

  void updateDigit(int idx, String val) {
    digits[idx] = val;
    notifyListeners();
  }

  Future<String?> verify() async {
    final otpCode = digits.join();

    // FRONTEND VALIDATION
    if (otpCode.length < 6) return 'Vui lòng nhập đủ 6 số OTP!';

    setLoading(true);
    try {
      final email = ForgotPassViewModel.recoveryEmail;
      final success = await _authHelper.verifyOTP(email, otpCode);
      if (success) return null;
      return 'Mã OTP không hợp lệ!';
    } catch (e) {
      return handleError(e);
    } finally {
      setLoading(false);
    }
  }

  Future<String?> resend() async {
    final email = ForgotPassViewModel.recoveryEmail;
    if (email.isEmpty) return 'Không tìm thấy email, vui lòng quay lại bước trước!';

    setLoading(true);
    try {
      await _authHelper.sendPasswordReset(email);
      return null;
    } catch (e) {
      return handleError(e);
    } finally {
      setLoading(false);
    }
  }
}

// ==========================================
// 5. NEW PASSWORD VIEWMODEL (Step 3)
// ==========================================
class NewPassViewModel extends BaseViewModel {
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();
  bool obscurePass = true;

  void togglePass() { obscurePass = !obscurePass; notifyListeners(); }

  Future<String?> updatePassword() async {
    final pass = passCtrl.text;
    final confirmPass = confirmPassCtrl.text;

    // FRONTEND VALIDATION: Strict checks before updating
    if (pass.isEmpty || confirmPass.isEmpty) {
      return 'Vui lòng nhập mật khẩu mới!';
    }
    if (pass.length < 6) {
      return 'Mật khẩu phải từ 6 ký tự trở lên!';
    }
    if (!isStrongPassword(pass)) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ hoa, thường, số và ký tự đặc biệt!';
    }
    if (pass != confirmPass) {
      return 'Mật khẩu xác nhận không khớp!';
    }

    setLoading(true);
    try {
      await _authHelper.updatePassword(pass);
      return null; // Success
    } catch (e) {
      return handleError(e);
    } finally {
      setLoading(false);
    }
  }
}

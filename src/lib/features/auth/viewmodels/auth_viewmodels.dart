import 'package:flutter/material.dart';

/// Base class to handle shared loading state
class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

class LoginViewModel extends BaseViewModel {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool obscurePass = true;

  void togglePass() { obscurePass = !obscurePass; notifyListeners(); }

  Future<String?> login() async {
    if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) return "Please enter all fields";
    setLoading(true);
    // Mock API call
    await Future.delayed(const Duration(seconds: 1));
    setLoading(false);
    return null; // Success
  }
}

class RegisterViewModel extends BaseViewModel {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();
  bool obscurePass = true;

  void togglePass() { obscurePass = !obscurePass; notifyListeners(); }

  Future<String?> register() async {
    if (passCtrl.text != confirmPassCtrl.text) return "Passwords do not match";
    setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    setLoading(false);
    return null;
  }
}

class ForgotPassViewModel extends BaseViewModel {
  final emailCtrl = TextEditingController();

  Future<String?> sendCode() async {
    if (emailCtrl.text.isEmpty) return "Please enter email";
    setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    setLoading(false);
    return null;
  }
}

class OtpViewModel extends BaseViewModel {
  // Updated to 8 digits to match UI
  List<String> digits = List.filled(8, "");

  void updateDigit(int idx, String val) { 
    if (idx < digits.length) {
      digits[idx] = val; 
      notifyListeners(); 
    }
  }

  Future<String?> verify() async {
    String code = digits.join();
    if (code.length < 8) return "Please enter 8-digit OTP";
    setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    setLoading(false);
    return null; // Success
  }

  // Added resend method to fix error in UI
  Future<String?> resend() async {
    setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    setLoading(false);
    return null; // Success
  }
}

class NewPassViewModel extends BaseViewModel {
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();
  bool obscurePass = true;

  void togglePass() { obscurePass = !obscurePass; notifyListeners(); }

  Future<String?> updatePassword() async {
    if (passCtrl.text != confirmPassCtrl.text) return "Passwords do not match";
    setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    setLoading(false);
    return null;
  }
}

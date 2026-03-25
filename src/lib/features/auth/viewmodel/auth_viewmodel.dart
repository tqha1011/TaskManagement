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

  Future<bool> login() async {
    if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) return false;
    setLoading(true);
    // Mock API call
    await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
    setLoading(false);
    return true; // Assume success
  }
}

class RegisterViewModel extends BaseViewModel {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();
  bool obscurePass = true;

  void togglePass() { obscurePass = !obscurePass; notifyListeners(); }

  Future<bool> register() async {
    if (passCtrl.text != confirmPassCtrl.text) return false;
    setLoading(true);
    await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
    setLoading(false);
    return true;
  }
}

class ForgotPassViewModel extends BaseViewModel {
  final emailCtrl = TextEditingController();

  Future<bool> sendCode() async {
    if (emailCtrl.text.isEmpty) return false;
    setLoading(true);
    await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
    setLoading(false);
    return true;
  }
}

class OtpViewModel extends BaseViewModel {
  List<String> digits = List.filled(6, "");

  void updateDigit(int idx, String val) { digits[idx] = val; notifyListeners(); }

  Future<bool> verify() async {
    if (digits.join().length < 6) return false;
    setLoading(true);
    await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
    setLoading(false);
    return true;
  }
}

class NewPassViewModel extends BaseViewModel {
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();
  bool obscurePass = true;

  void togglePass() { obscurePass = !obscurePass; notifyListeners(); }

  Future<bool> updatePassword() async {
    if (passCtrl.text != confirmPassCtrl.text) return false;
    setLoading(true);
    await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
    setLoading(false);
    return true;
  }
}
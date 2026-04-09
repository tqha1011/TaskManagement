// services/helpers/auth_helper.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/user_model.dart';
import 'package:task_management_app/main.dart';

class AuthHelper {


  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        final userId = user.id;
        final userMetadata = user.userMetadata ?? {};
        final String? username = userMetadata['username']?.toString();
        final timezoneObj = await FlutterTimezone.getLocalTimezone();
        final String currentTimezone = timezoneObj.toString();

        final profileData = await supabase
            .from('profile')
            .upsert({
              'id': userId,
              if (username != null && username.isNotEmpty) 'username': username,
              'timezone': currentTimezone,
            })
            .select()
            .single();

        return UserModel.fromJson(profileData, email);
      }
      return null;
    } on AuthException catch (e) {
      print('Supabase Auth Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      rethrow;
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      return await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'taskapp://login-callback', // back to app
      );
    } on AuthException catch (e) {
      print('Lỗi đăng nhập Google: ${e.message}');
      return false;
    }
  }

  Future<bool> loginWithFacebook() async {
    try {
      return await supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'taskapp://login-callback', // back to app
      );
    } on AuthException catch (e) {
      print('Lỗi đăng nhập Facebook: ${e.message}');
      return false;
    }
  }

  Future<UserModel?> register(String email, String password, String username) async {
    try {
      final timezoneObj = await FlutterTimezone.getLocalTimezone();
      final String currentTimezone = timezoneObj.toString();
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
          data: {
            'username': username,
            'timezone': currentTimezone, // Data is already a safe String
          }
      );

      final user = response.user;
      if (user != null) {
        if (response.session == null) {
          // Email confirmation may be required; skip profile write until login.
          return UserModel(
            id: user.id,
            email: email,
            username: username,
            timezone: currentTimezone,
          );
        }

        final profileData = await supabase
            .from('profile')
            .upsert({
              'id': user.id,
              'username': username,
              'timezone': currentTimezone,
            })
            .select()
            .single();

        return UserModel.fromJson(profileData, email);
      }
      return null;
    } on AuthException catch (e) {
      print('Supabase Sign Up Error: ${e.message}');
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      print('Lỗi Gửi OTP: ${e.message}');
      rethrow;
    }
  }

  Future<bool> verifyOTP(String email, String otpCode) async {
    try {
      // Authenticate OTP for recovery type
      final response = await supabase.auth.verifyOTP(
        email: email,
        token: otpCode,
        type: OtpType.recovery,
      );
      // Returns true if authentication is successful and session is created
      return response.session != null;
    } on AuthException catch (e) {
      print('Lỗi Xác thực OTP: ${e.message}');
      return false;
    }
  }
  Future<void> updatePassword(String newPassword) async {
    try {
      // After successful verifyOTP, user is automatically logged in
      // At this point, just call updateUser to change the password
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      print('Lỗi Đổi Pass: ${e.message}');
      rethrow;
    }
  }
}

// SignOut session
Future<void> signOut() async {
  try {
    await supabase.auth.signOut();
  } catch (e) {
    print('Lỗi đăng xuất: $e');
    rethrow;
  }
}
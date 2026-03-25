// data/helpers/auth_helper.dart

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

      if (response.user != null) {
        final userId = response.user!.id;

        final timezoneObj = await FlutterTimezone.getLocalTimezone();
        final String currentTimezone = timezoneObj.toString();

        final profileData = await supabase
            .from('profile')
            .update({'timezone': currentTimezone})
            .eq('id', userId)
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

      if (response.user != null) {
        final userId = response.user!.id;

        // Step 2: Insert directly into the 'profile' table
        final profileData = await supabase
            .from('profile')
            .select()
            .eq('id', userId)
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
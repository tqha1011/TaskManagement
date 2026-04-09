import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/view/auth_gate.dart';
import '../model/user_profile_model.dart';
import '../service/user_service.dart';

class UserProfileViewModel extends ChangeNotifier {
  final UserService _userService = UserService();

  final _supabase = Supabase.instance.client;

  UserProfileModel? _user;
  UserProfileModel? get user => _user;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  /// Load profile data
  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _userService.fetchUserProfile();
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle notification preference
  void toggleNotification(bool value) {
    if (_user != null) {
      _user!.isNotificationEnabled = value;
      notifyListeners();
      // Ghi chú: Có thể dùng SharedPreferences để lưu local setting này
    }
  }

  /// Handle theme/appearance change
  void updateAppearance(String newAppearance) {
    if (_user != null) {
      _user!.appearance = newAppearance;
      notifyListeners();
      // Ghi chú: Chỗ này thường sẽ gọi Provider quản lý Theme tổng của App
    }
  }


  Future<void> logout(BuildContext context) async {
    try {
      await _supabase.auth.signOut();
      debugPrint("Đã clear session trên Supabase.");

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthGate()),
              (route) => false,
        );
      }

    } catch (e) {
      debugPrint("Lỗi đăng xuất: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng xuất: $e')),
        );
      }
    }
  }
}
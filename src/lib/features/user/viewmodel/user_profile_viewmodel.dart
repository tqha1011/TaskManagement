import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart'; // Import thêm Provider

import '../../../core/theme/theme_provider.dart';
import '../../auth/presentation/view/auth_gate.dart';
import '../model/user_profile_model.dart';
import '../service/user_service.dart';

class UserProfileViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  final _supabase = Supabase.instance.client;
  final bool useMockData;
  String? _lastAppliedAppearance;

  UserProfileViewModel({this.useMockData = true});

  UserProfileModel? _user;
  UserProfileModel? get user => _user;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  /// Load profile data
  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (useMockData) {
        await Future.delayed(const Duration(milliseconds: 400));
        _user = _buildMockUser();
      } else {
        _user = await _userService.fetchUserProfile();
      }
      _lastAppliedAppearance = null;
    } catch (e) {
      debugPrint("Error loading profile: $e");
      _user = _buildMockUser();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  UserProfileModel _buildMockUser() {
    return UserProfileModel(
      id: 'mock-user-001',
      name: 'Alex Thompson',
      // Valid URL so profile header can test normal network-avatar path.
      avatarUrl: 'https://i.pravatar.cc/300?img=12',
      appearance: 'Dark',
      tasksDone: 24,
      streaks: 12,
      isNotificationEnabled: true,
    );
  }

  /// Toggle notification preference
  void toggleNotification(bool value) {
    if (_user != null) {
      _user!.isNotificationEnabled = value;
      notifyListeners();
    }
  }


  void updateAppearance(BuildContext context, String newAppearance) {
    if (_user != null) {
      _user!.appearance = newAppearance;
      _lastAppliedAppearance = newAppearance;
      notifyListeners();

      if (context.mounted) {
         context.read<ThemeProvider>().updateTheme(newAppearance);
      }
    }
  }

  void syncThemeWithProfile(BuildContext context) {
    if (_user == null) return;
    if (_lastAppliedAppearance == _user!.appearance) return;

    _lastAppliedAppearance = _user!.appearance;
    context.read<ThemeProvider>().updateTheme(_user!.appearance);
  }

  /// Logout
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
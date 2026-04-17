import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      if (useMockData) {
        _user = _buildMockUser();
      } else {
        _user = null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  UserProfileModel _buildMockUser() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final Map<DateTime, int> mockHeatmapData = {
      today.subtract(const Duration(days: 1)): 3,
      today.subtract(const Duration(days: 2)): 7,
      today.subtract(const Duration(days: 3)): 4,
      today.subtract(const Duration(days: 4)): 8,
      today.subtract(const Duration(days: 5)): 2,
      today.subtract(const Duration(days: 8)): 5,
    };
    return UserProfileModel(
      id: 'mock-user-001',
      name: 'Alex Thompson',
      avatarUrl: 'https://i.pravatar.cc/300?img=12',
      appearance: 'Dark',
      tasksDone: 24,
      streaks: 12,
      isNotificationEnabled: true,
      heatmapData: mockHeatmapData,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi đăng xuất: $e')));
      }
    }
  }
}

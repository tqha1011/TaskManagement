import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart'; // Import thêm Provider

import '../../../core/services/notification_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/presentation/view/auth_gate.dart';
import '../model/user_profile_model.dart';
import '../service/user_service.dart';

import '../service/profile_update_service.dart';

class UserProfileViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  final ProfileUpdateService _profileUpdateService = ProfileUpdateService();
  final _supabase = Supabase.instance.client;
  final bool useMockData;
  final NotificationService _notificationService = NotificationService();
  String? _lastAppliedAppearance;

  UserProfileViewModel({this.useMockData = false});

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

      if (_user != null) {
        final isEnabled = await _notificationService.getNotificationEnabled();
        _user!.isNotificationEnabled = isEnabled;
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
  Future<void> toggleNotification(bool value) async {
    if (_user == null) return;
    _user!.isNotificationEnabled = value;
    notifyListeners();
    await _notificationService.updateNotificationSettings(isEnabled: value);
  }

  Future<void> updateAvatar(BuildContext context) async {
    final newUrl = await _profileUpdateService.uploadAndSaveAvatar();
    if (newUrl != null) {
      await loadProfile();
      if (context.mounted) {
        _showModernSnackBar(
          context,
          'Cập nhật ảnh đại diện thành công!',
          Icons.check_circle_rounded,
          Theme.of(context).colorScheme.primary,
        );
      }
    } else {
      if (context.mounted) {
        _showModernSnackBar(
          context,
          'Cập nhật ảnh đại diện thất bại.',
          Icons.error_outline_rounded,
          Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  Future<void> updateUsername(String newName) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('profile').update({'username': newName}).eq('id', user.id);
      await loadProfile();
    } catch (e) {
      debugPrint("Error updating username: $e");
      rethrow;
    }
  }

  Future<void> updatePassword(String oldPassword, String newPassword) async {
    try {
      // Supabase handle password update via updateUser
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      debugPrint("Error updating password: $e");
      rethrow;
    }
  }

  Future<void> updateAppearance(BuildContext context, String newAppearance) async {
    if (_user == null) return;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // 1. Update DB
      await _supabase
          .from('profile')
          .update({'appearance': newAppearance})
          .eq('id', user.id);

      // 2. Update Local State
      _user!.appearance = newAppearance;
      _lastAppliedAppearance = newAppearance;
      notifyListeners();

      // 3. Update Theme Provider
      if (context.mounted) {
        context.read<ThemeProvider>().updateTheme(newAppearance);
        _showModernSnackBar(
          context,
          'Đã đổi sang giao diện $newAppearance',
          Icons.palette_rounded,
          Theme.of(context).colorScheme.primary,
        );
      }
    } catch (e) {
      debugPrint("Error updating appearance: $e");
      if (context.mounted) {
        _showModernSnackBar(
          context,
          'Lỗi khi đổi giao diện: $e',
          Icons.error_outline_rounded,
          Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  void _showModernSnackBar(
    BuildContext context,
    String message,
    IconData icon,
    Color color,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

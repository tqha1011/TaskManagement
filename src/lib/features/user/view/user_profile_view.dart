import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/notification_time_picker.dart';
import 'screens/update_password_screen.dart';
import '../viewmodel/user_profile_viewmodel.dart';
import 'widgets/logout_button.dart';
import 'widgets/profile_header.dart';
import 'widgets/settings_list_tile.dart';
import 'widgets/settings_section.dart';
import 'widgets/stat_card.dart';

class UserProfileView extends StatelessWidget {
  const UserProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {},
            splashRadius: 24,
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<UserProfileViewModel>(
          builder: (context, vm, child) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: vm.isLoading
                  ? Center(
                      key: const ValueKey('loading'),
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : vm.user == null
                  ? const Center(
                      key: ValueKey('error'),
                      child: Text("Error loading profile"),
                    )
                  : Builder(
                      builder: (innerContext) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          vm.syncThemeWithProfile(innerContext);
                        });
                        return _buildProfileContent(innerContext, vm);
                      },
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserProfileViewModel vm) {
    final user = vm.user!;
    return SingleChildScrollView(
      key: const ValueKey('content'),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        children: [
          // 1. Header (Avatar & Name)
          ProfileHeader(user: user),
          const SizedBox(height: 32),

          // 2. Stats Row
          Row(
            children: [
              Expanded(
                child: StatCard(
                  value: user.tasksDone.toString(),
                  label: 'Tasks Done',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  value: user.streaks.toString(),
                  label: 'Streaks',
                  onTap: () => _showHeatmapBottomSheet(context, vm),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          SettingsSection(
            title: 'Account Settings',
            children: [
              SettingsListTile(
                icon: Icons.person_outline,
                title: 'Username',
                trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                onTap: () => _showUpdateUsernameModal(context, vm),
              ),
              Divider(height: 1, indent: 64, endIndent: 24, color: Theme.of(context).colorScheme.outline),
              SettingsListTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const UpdatePasswordScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: animation.drive(Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.ease))),
                          child: child,
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          SettingsSection(
            title: 'Preferences',
            children: [
              SettingsListTile(
                icon: Icons.notifications,
                title: 'Notifications',
                iconBgColor: Theme.of(context).colorScheme.outline,
                iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const NotificationTimePicker(),
                ),
                trailing: Switch(
                  value: user.isNotificationEnabled,
                  activeThumbColor: Theme.of(context).colorScheme.surface,
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                  inactiveThumbColor: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant,
                  inactiveTrackColor: Theme.of(context).colorScheme.outline,
                  onChanged: (val) => vm.toggleNotification(val),
                ),
              ),
              Divider(
                height: 1,
                indent: 64,
                endIndent: 24,
                color: Theme.of(context).colorScheme.outline,
              ),
              SettingsListTile(
                icon: Icons.dark_mode,
                title: 'Appearance',
                iconBgColor: Theme.of(context).colorScheme.outline,
                iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                trailing: Text(
                  user.appearance,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () => vm.updateAppearance(
                  context,
                  user.appearance == 'Dark' ? 'Light' : 'Dark',
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // 4. Logout Button
          LogoutButton(onPressed: () => vm.logout(context)),
        ],
      ),
    );
  }

  void _showHeatmapBottomSheet(BuildContext context, UserProfileViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Bản đồ hoạt động',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Giữ vững phong độ nhé! 🔥',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                Center(
                  child: HeatMap(
                    datasets: vm.user!.heatmapData,
                    colorMode: ColorMode.opacity,
                    showText: false,
                    scrollable: true,
                    size: 30,

                    colorsets: {
                      1: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                      3: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.4),
                      5: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.6),
                      7: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.8),
                      9: Theme.of(context).colorScheme.primary,
                    },
                    onClick: (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã hoàn thành $value công việc'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showUpdateUsernameModal(BuildContext context, UserProfileViewModel vm) {
    final controller = TextEditingController(text: vm.user?.name);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đổi Username',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Username mới',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await vm.updateUsername(controller.text);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã cập nhật username thành công!'), behavior: SnackBarBehavior.floating),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e'), behavior: SnackBarBehavior.floating),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Xác nhận'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

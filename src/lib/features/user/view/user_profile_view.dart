import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';

import '../viewmodel/user_profile_viewmodel.dart';
import 'widgets/profile_header.dart';
import 'widgets/stat_card.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_list_tile.dart';
import 'widgets/logout_button.dart';

class UserProfileView extends StatelessWidget {
  const UserProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.primaryBlue),
            onPressed: () {},
            splashRadius: 24,
          ),
        ],
      ),
      body: Consumer<UserProfileViewModel>(
        builder: (context, vm, child) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: vm.isLoading
                ? const Center(
              key: ValueKey('loading'),
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
                : vm.user == null
                ? const Center(
              key: ValueKey('error'),
              child: Text("Error loading profile"),
            )
                : _buildProfileContent(context, vm),
          );
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserProfileViewModel vm) {
    final user = vm.user!;
    return SingleChildScrollView(
      key: const ValueKey('content'),
      physics: const BouncingScrollPhysics(),
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
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          SettingsSection(
            title: 'Preferences',
            children: [
              SettingsListTile(
                icon: Icons.notifications,
                title: 'Notifications',
                iconBgColor: AppColors.border,
                iconColor: AppColors.grayText,
                onTap: () => vm.toggleNotification(!user.isNotificationEnabled),
                trailing: Switch(
                  value: user.isNotificationEnabled,
                  activeColor: AppColors.white,
                  activeTrackColor: AppColors.primaryBlue,
                  inactiveThumbColor: AppColors.grayText,
                  inactiveTrackColor: AppColors.border,
                  onChanged: (val) => vm.toggleNotification(val),
                ),
              ),
              const Divider(height: 1, indent: 64, endIndent: 24, color: AppColors.border),
              SettingsListTile(
                icon: Icons.dark_mode,
                title: 'Appearance',
                iconBgColor: AppColors.border,
                iconColor: AppColors.grayText,
                trailing: Text(
                  user.appearance,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grayText,
                  ),
                ),
                onTap: () {},
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
}
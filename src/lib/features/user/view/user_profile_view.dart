import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      body: Consumer<UserProfileViewModel>(
        builder: (context, vm, child) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: vm.isLoading
                ? Center(
              key: ValueKey('loading'),
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
                      vm.syncThemeWithProfile(innerContext);
                      return _buildProfileContent(innerContext, vm);
                    },
                  ),
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
                iconBgColor: Theme.of(context).colorScheme.outline,
                iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                onTap: () => vm.toggleNotification(!user.isNotificationEnabled),
                trailing: Switch(
                  value: user.isNotificationEnabled,
                  activeColor: Theme.of(context).colorScheme.surface,
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                  inactiveThumbColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
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
}
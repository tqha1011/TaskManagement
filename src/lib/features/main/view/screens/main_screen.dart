import 'package:flutter/material.dart';
// import '../../../tasks/view/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:task_management_app/features/chatbot/view/chatbot_view.dart';
import 'package:task_management_app/features/statistics/viewmodel/statistics_viewmodel.dart';
import 'package:task_management_app/features/tasks/view/screens/home_screen.dart';
import 'package:task_management_app/features/user/viewmodel/user_profile_viewmodel.dart';
import 'package:task_management_app/features/tasks/viewmodel/task_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../category/viewmodel/category_viewmodel.dart';
import '../../../note/view/focus_screen.dart';
import '../../../note/viewmodel/focus_viewmodel.dart';
import '../../../statistics/view/screens/statistics_screen.dart';
import '../../../tag/viewmodel/tag_viewmodel.dart';
import '../../../user/view/user_profile_view.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const Center(child: HomeScreen()),
    const ChatBotView(),
    ChangeNotifierProvider(
      create: (_) => FocusViewModel(),
      child: const FocusScreen(),
    ),
    const StatisticsScreen(),
    const UserProfileView(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryViewModel>().loadCategories();
      context.read<TagViewModel>().loadTags();
      context.read<TaskViewModel>().fetchTasks();
      context.read<UserProfileViewModel>().loadProfile();
    });
  }

  void _handleNavTap(BuildContext context, int index) {
    setState(() => _currentIndex = index);

    if (index == 3) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        context.read<StatisticsViewmodel>().getStatisticsData(userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // --- SYNC THEME WITH PROFILE ON LOAD ---
    final userVm = context.watch<UserProfileViewModel>();
    if (!userVm.isLoading && userVm.user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        userVm.syncThemeWithProfile(context);
      });
    }

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1A2945)
              : Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, Icons.checklist_rounded, 'Công việc', 0),
              _buildNavItem(context, Icons.smart_toy_rounded, 'Chat', 1),
              _buildNavItem(context, Icons.timer_rounded, 'Tập trung', 2),
              _buildNavItem(context, Icons.bar_chart_rounded, 'Thống kê', 3),
              _buildNavItem(context, Icons.person_2_rounded, 'Cá nhân', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _handleNavTap(context, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 15 : 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF23395D)
                    : const Color(0xFFE8F0FE))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

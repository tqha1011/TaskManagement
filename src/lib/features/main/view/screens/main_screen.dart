import 'package:flutter/material.dart';
import 'package:task_management_app/features/statistics/viewmodel/statistics_viewmodel.dart';
import 'package:task_management_app/features/tasks/view/screens/home_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../statistics/view/screens/statistics_screen.dart';
// import '../../../tasks/view/screens/home_screen.dart'; 
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const Center(child: HomeScreen()),
    const Center(child: Text('Màn hình Lịch')),
    const Center(child: Text('Màn hình Tập trung')),
    ChangeNotifierProvider(
        create: (_) => StatisticsViewmodel(),
        child: const StatisticsScreen(),
    ),
    const Center(child: Text('Màn hình Cài đặt')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.checklist_rounded, 'Công việc', 0),
              _buildNavItem(Icons.calendar_today_rounded, 'Lịch', 1),
              _buildNavItem(Icons.timer_rounded, 'Tập trung', 2),
              _buildNavItem(Icons.bar_chart_rounded, 'Thống kê', 3),
              _buildNavItem(Icons.settings_rounded, 'Cài đặt', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 15 : 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F0FE) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryBlue : AppColors.grayText, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primaryBlue : AppColors.grayText,
              ),
            )
          ],
        ),
      ),
    );
  }
}
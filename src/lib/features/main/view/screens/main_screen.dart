import 'package:flutter/material.dart';
import 'package:task_management_app/features/tasks/view/screens/home_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../statistics/view/screens/statistics_screen.dart';
// import '../../../tasks/view/screens/home_screen.dart'; // Màn hình Home bạn đã làm

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // Mặc định mở tab công việc

  // Danh sách các màn hình tương ứng với các tab
  final List<Widget> _screens = [
    const Center(child: const HomeScreen()),
    const Center(child: Text('Màn hình Lịch')),
    const Center(child: Text('Màn hình Tập trung')),
    const StatisticsScreen(), // Màn hình Thống kê vừa tạo
    const Center(child: Text('Màn hình Cài đặt')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Cho phép body chui xuống dưới bottom bar (để làm bar nổi/trong suốt nếu muốn)
      body: IndexedStack(
        index: _currentIndex,
        children: _screens, // IndexedStack giúp giữ state của các tab không bị reset khi chuyển qua lại
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

  // Hàm tạo từng item trên bottom bar với hiệu ứng AnimatedContainer
  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 15 : 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F0FE) : Colors.transparent, // Nền xanh nhạt khi được chọn
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
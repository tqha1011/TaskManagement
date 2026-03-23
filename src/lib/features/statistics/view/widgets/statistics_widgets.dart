import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../tasks/model/task_model.dart';
import '../../../tasks/view/screens/task_detail_screen.dart';

// --- 1. Widget Tiến độ hôm nay ---
class DailyProgressCard extends StatelessWidget {
  const DailyProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          const Text('Tiến độ hôm nay', style: TextStyle(color: AppColors.grayText, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            width: 140,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 0.8,
                  strokeWidth: 12,
                  backgroundColor: AppColors.backgroundBlue,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('8/10', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                    Text('Công việc', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(fontSize: 16, color: Colors.black87),
              children: [
                TextSpan(text: 'Tuyệt vời! Bạn đã hoàn thành '),
                TextSpan(text: '80%', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                TextSpan(text: '\nmục tiêu.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- 2. Widget Biểu đồ tuần ---
class WeeklyChartCard extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDaySelected;

  const WeeklyChartCard({
    super.key,
    required this.selectedIndex,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tuần này', style: TextStyle(color: AppColors.grayText, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  const Text('42 Tasks', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFE9F7EF), borderRadius: BorderRadius.circular(15)),
                child: const Text('+12% vs tuần trước', style: TextStyle(color: Color(0xFF2ECC71), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar('T2', 0.4, 0),
              _buildBar('T3', 0.6, 1),
              _buildBar('T4', 1.0, 2),
              _buildBar('T5', 0.5, 3),
              _buildBar('T6', 0.4, 4),
              _buildBar('T7', 0.3, 5),
              _buildBar('CN', 0.2, 6),
            ],
          ),
        ],
      ),
    );
  }

  // Hàm build từng cột, truyền thêm tham số index để nhận diện
  Widget _buildBar(String label, double heightRatio, int index) {
    bool isActive = index == selectedIndex;

    return GestureDetector(
      onTap: () => onDaySelected(index), // Bắn sự kiện ra ngoài khi bị bấm
      behavior: HitTestBehavior.opaque, // Giúp vùng chạm rộng hơn, dễ bấm hơn
      child: Column(
        children: [
          AnimatedContainer( // Thêm hiệu ứng mượt mà khi cột thay đổi độ cao/màu sắc
            duration: const Duration(milliseconds: 300),
            width: 35,
            height: 100 * heightRatio,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryBlue : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? AppColors.primaryBlue : AppColors.grayText)),
        ],
      ),
    );
  }
}

// --- 3. Widget Thẻ Task Đã Hoàn Thành (Có Hero Animation) ---
class CompletedTaskCard extends StatelessWidget {
  final TaskModel task;
  final Widget icon;

  const CompletedTaskCard({super.key, required this.task, required this.icon});

  @override
  Widget build(BuildContext context) {
    // Format thời gian hoàn thành (Lấy từ startTime của task)
    final period = task.startTime.period == DayPeriod.am ? 'AM' : 'PM';
    final hour = task.startTime.hourOfPeriod == 0 ? 12 : task.startTime.hourOfPeriod;
    final minute = task.startTime.minute.toString().padLeft(2, '0');
    final timeString = 'Hoàn thành lúc $hour:$minute $period';

    return Hero(
      tag: 'task_card_${task.id}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () {
            // Chuyển hướng sang màn hình chi tiết đã làm trước đó
            Navigator.push(context, PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (_, __, ___) => TaskDetailScreen(task: task),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF1F7FD), borderRadius: BorderRadius.circular(15)),
                  child: icon,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                      const SizedBox(height: 4),
                      Text(timeString, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: Color(0xFF2ECC71), size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
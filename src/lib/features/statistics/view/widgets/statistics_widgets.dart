import 'package:flutter/material.dart';
import 'package:task_management_app/features/statistics/model/StatisticsModel.dart';
import '../../../tasks/model/task_model.dart';
import '../../../tasks/view/screens/task_detail_screen.dart';

class DailyProgressCard extends StatelessWidget {
  final int total;
  final int completed;
  final double percentage;
  const DailyProgressCard({super.key, required this.total, required this.completed, required this.percentage});

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
          Text(
            'Tiến độ hôm nay',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            width: 140,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: (total > 0) ? percentage / 100 : 0,
                  strokeWidth: 12,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$completed/$total', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                    Text('Công việc', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              children: [
                const TextSpan(text: 'Tuyệt vời! Bạn đã hoàn thành '),
                TextSpan(
                  text: '${percentage.toInt()}%',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: '\nmục tiêu.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class WeeklyChartCard extends StatelessWidget {
  final int selectedIndex;
  final int thisWeekTotal;
  final double growthPercentage;
  final List<double> weeklyHeights;
  final ValueChanged<int> onDaySelected;

  const WeeklyChartCard({
    super.key,
    required this.selectedIndex,
    required this.onDaySelected,
    required this.thisWeekTotal,
    required this.growthPercentage,
    required this.weeklyHeights,
  });

  @override
  Widget build(BuildContext context) {

    final bool isPositive = growthPercentage >= 0;
    final Color trendColor = isPositive ? const Color(0xFF2ECC71) : Colors.redAccent;
    final Color trendBgColor = isPositive ? const Color(0xFFE9F7EF) : const Color(0xFFFFEBEE);
    final String trendText = "${isPositive ? '+' : ''}$growthPercentage% vs tuần trước";

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
                  Text(
                    'Tuần này',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text('$thisWeekTotal Tasks', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: trendBgColor, borderRadius: BorderRadius.circular(15)),
                child: Text(trendText, style: TextStyle(color: trendColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [

              _buildBar(context, 'T2', weeklyHeights.length > 0 ? weeklyHeights[0] : 0.1, 0),
              _buildBar(context, 'T3', weeklyHeights.length > 1 ? weeklyHeights[1] : 0.1, 1),
              _buildBar(context, 'T4', weeklyHeights.length > 2 ? weeklyHeights[2] : 0.1, 2),
              _buildBar(context, 'T5', weeklyHeights.length > 3 ? weeklyHeights[3] : 0.1, 3),
              _buildBar(context, 'T6', weeklyHeights.length > 4 ? weeklyHeights[4] : 0.1, 4),
              _buildBar(context, 'T7', weeklyHeights.length > 5 ? weeklyHeights[5] : 0.1, 5),
              _buildBar(context, 'CN', weeklyHeights.length > 6 ? weeklyHeights[6] : 0.1, 6),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(BuildContext context, String label, double heightRatio, int index) {
    bool isActive = index == selectedIndex;
    return GestureDetector(
      onTap: () => onDaySelected(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 35,
            height: 100 * (heightRatio > 0 ? heightRatio : 0.1), // Tối thiểu 10% để cột không bị "biến mất"
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

//
class CompletedTaskCard extends StatelessWidget {
  final RecentTaskModel task;
  final Widget icon;

  const CompletedTaskCard({super.key, required this.task, required this.icon});

  @override
  Widget build(BuildContext context) {

    final time = task.updatedAt;
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final timeString = 'Hoàn thành lúc $hour:$minute $period';

    return Hero(
      tag: 'task_card_${task.id}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () {
            final mappedTask = TaskModel(
              id: task.id.toString(), // Convert int to String if your TaskModel uses String IDs
              title: task.title,
              description: 'Completed task details from Statistics.', // Default filler
              category: 'Development', // Default filler
              startTime: TimeOfDay(hour: task.updatedAt.hour, minute: task.updatedAt.minute),
              endTime: TimeOfDay(hour: task.updatedAt.hour + 1, minute: task.updatedAt.minute), // Add 1 hour just for display
              date: task.updatedAt,
            );

            Navigator.push(context, PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (_, __, ___) => TaskDetailScreen(task: mappedTask),
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
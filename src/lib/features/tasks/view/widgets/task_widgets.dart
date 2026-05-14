import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/task_model.dart';
import '../screens/task_detail_screen.dart';

// --- Clipper for the blue wavy strip ---
class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0.0, size.height);
    var firstControlPoint = Offset(size.width / 4, size.height + 20);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint =
    Offset(size.width - (size.width / 3.25), size.height - 65);
    var secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0.0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// --- Widget for date box in Timeline ---
class DateBox extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  const DateBox({super.key, required this.date, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    String day = DateFormat('d').format(date);
    String weekday = DateFormat('E').format(date).toUpperCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 55,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Theme.of(context).colorScheme.outline
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(day,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 5),
          Text(weekday,
              style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// --- Widget cho thẻ tác vụ (Task Card) ---
class TaskCard extends StatelessWidget {
  final TaskModel task;
  final Widget leading;
  final Widget? trailing; // 1. Thêm biến trailing để nhận nhãn Priority

  const TaskCard({
    super.key,
    required this.task,
    required this.leading,
    this.trailing, // 2. Bổ sung vào constructor
  });

  @override
  Widget build(BuildContext context) {
    // Format thời gian hiển thị
    final period = task.startTime.period == DayPeriod.am ? 'AM' : 'PM';
    final hour = task.startTime.hourOfPeriod == 0 ? 12 : task.startTime.hourOfPeriod;
    final minute = task.startTime.minute.toString().padLeft(2, '0');
    final timeString = '$hour:$minute $period';

    return Hero(
      tag: 'task_card_${task.id}', // Tag nối thẻ từ màn Home sang màn Detail
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () {
            // Hiệu ứng FadeRoute để chuyển cảnh mượt hơn Route mặc định
            Navigator.push(context, PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (_, _, _) => TaskDetailScreen(task: task),
              transitionsBuilder: (_, animation, _, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0, top: 25, bottom: 25, width: 4,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.only(topRight: Radius.circular(5), bottomRight: Radius.circular(5))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      leading,
                      const SizedBox(width: 15),
                      // Phần tiêu đề và mô tả
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.title, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 3),
                            Text(task.description, style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (task.totalSubtasks > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      task.completedSubtasks == task.totalSubtasks 
                                          ? Icons.check_circle_rounded 
                                          : Icons.checklist_rounded, 
                                      size: 14, 
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${task.completedSubtasks}/${task.totalSubtasks}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.primary,
                                        decoration: task.completedSubtasks == task.totalSubtasks 
                                            ? TextDecoration.lineThrough 
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 10),
                      
                      // 3. CỤM HIỂN THỊ TRÊN GÓC PHẢI (Priority đè lên Time)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (trailing != null) ...[
                            trailing!, // Hiển thị nhãn Priority ở đây
                            const SizedBox(height: 8), // Cách cái giờ ra một tí
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(timeString, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// --- Widget chọn giờ (TimePickerWidget) ---
class TimePickerWidget extends StatelessWidget {
  final TimeOfDay time;
  final Function(TimeOfDay) onChanged;
  const TimePickerWidget(
      {super.key, required this.time, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final formattedTime = '$hour:$minute $period';

    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
            context: context, initialTime: time);
        if (picked != null && picked != time) onChanged(picked);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(formattedTime,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  )),
              const SizedBox(width: 5), 
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              )
            ],
          ),
          const SizedBox(height: 5),
          Container(height: 1, color: Theme.of(context).colorScheme.outline)
        ],
      ),
    );
  }
}
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
    final theme = Theme.of(context);

    return Container(
      width: 55,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline,
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
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface)),
          const SizedBox(height: 5),
          Text(weekday,
              style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// --- Animated wrapper to slide out completed tasks quickly ---
class AnimatedTaskCard extends StatefulWidget {
  final TaskModel task;
  final Widget leading;
  final Widget? trailing;
  final Future<void> Function() onQuickComplete;

  const AnimatedTaskCard({
    super.key,
    required this.task,
    required this.leading,
    required this.onQuickComplete,
    this.trailing,
  });

  @override
  State<AnimatedTaskCard> createState() => _AnimatedTaskCardState();
}

class _AnimatedTaskCardState extends State<AnimatedTaskCard> {
  bool _isRemoving = false;

  Future<void> _handleQuickComplete() async {
    if (_isRemoving) return;
    setState(() => _isRemoving = true);
    // Let the exit animation finish before updating the data source.
    await Future.delayed(const Duration(milliseconds: 240));
    try {
      await widget.onQuickComplete();
    } catch (e) {
      // If the backend call fails, restore the card visually.
      if (mounted) {
        setState(() => _isRemoving = false);
      }
      debugPrint("Quick Complete Failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero)
            .animate(animation);
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: _isRemoving
          ? const SizedBox.shrink(key: ValueKey('task_removed'))
          : TaskCard(
              key: ValueKey('task_${widget.task.id}'),
              task: widget.task,
              leading: widget.leading,
              trailing: widget.trailing,
              onQuickComplete: _handleQuickComplete,
            ),
    );
  }
}

// --- Widget cho thẻ tác vụ (Task Card) ---
class TaskCard extends StatelessWidget {
  final TaskModel task;
  final Widget leading;
  final Widget? trailing;
  final VoidCallback? onQuickComplete;

  const TaskCard({
    super.key,
    required this.task,
    required this.leading,
    this.trailing,
    this.onQuickComplete,
  });

  @override
  Widget build(BuildContext context) {
    // Format thời gian hiển thị
    final period = task.startTime.period == DayPeriod.am ? 'AM' : 'PM';
    final hour = task.startTime.hourOfPeriod == 0 ? 12 : task.startTime.hourOfPeriod;
    final minute = task.startTime.minute.toString().padLeft(2, '0');
    final timeString = '$hour:$minute $period';
    final isCompleted = task.isCompleted;

    return Hero(
      tag: 'task_card_${task.id}', // Tag nối thẻ từ màn Home sang màn Detail
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
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
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0, top: 18, bottom: 18, width: 3,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      leading,
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                                      color: isCompleted
                                          ? Theme.of(context).colorScheme.onSurfaceVariant
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (task.totalSubtasks > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                    ),
                                    child: Text(
                                      '${task.completedSubtasks}/${task.totalSubtasks}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        height: 1,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      textHeightBehavior: const TextHeightBehavior(
                                        applyHeightToFirstAscent: false,
                                        applyHeightToLastDescent: false,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              task.description,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                color: isCompleted
                                    ? Theme.of(context).colorScheme.onSurfaceVariant
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isCompleted && onQuickComplete != null) ...[
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.circle_outlined),
                              color: Theme.of(context).colorScheme.primary,
                              tooltip: 'Mark completed',
                              onPressed: onQuickComplete,
                            ),
                            const SizedBox(height: 2),
                          ],
                          if (trailing != null) ...[
                            trailing!,
                            const SizedBox(height: 6),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              timeString,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                                fontSize: 11,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
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
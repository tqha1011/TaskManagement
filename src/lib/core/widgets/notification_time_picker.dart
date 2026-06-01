import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../../features/tasks/viewmodel/task_viewmodel.dart';
import '../../features/tasks/model/task_model.dart';

class NotificationTimePicker extends StatefulWidget {
  const NotificationTimePicker({super.key});

  @override
  State<NotificationTimePicker> createState() => _NotificationTimePickerState();
}

class _NotificationTimePickerState extends State<NotificationTimePicker> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isEnabled = false;
  final _service = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadSavedTime();
  }

  Future<void> _loadSavedTime() async {
    final saved = await _service.getSavedTime();
    final enabled = await _service.getNotificationEnabled();
    if (!mounted) return;
    setState(() {
      _selectedTime = saved;
      _isEnabled = enabled;
    });
    if (enabled) {
      await _service.registerDailyTask(saved);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
      if (_isEnabled) {
        await _service.updateNotificationSettings(
          isEnabled: true,
          time: _selectedTime,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã đặt thông báo lúc ${_selectedTime.format(context)} mỗi ngày',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Thông báo buổi sáng',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Nhắc nhở tổng quan task theo mức độ ưu tiên',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Toggle bật/tắt
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bật thông báo',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              Switch(
                value: _isEnabled,
                onChanged: (val) async {
                  setState(() => _isEnabled = val);
                  await _service.updateNotificationSettings(
                    isEnabled: val,
                    time: _selectedTime,
                  );
                  if (!context.mounted) return;
                  if (val) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đã đặt thông báo lúc ${_selectedTime.format(context)} mỗi ngày',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã tắt thông báo'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),

          // Chọn giờ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Giờ thông báo',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedTime.format(context),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _isEnabled
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _isEnabled ? _pickTime : null,
                icon: const Icon(Icons.access_time),
                label: const Text('Đổi giờ'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Preview thông báo
          if (_isEnabled) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Consumer<TaskViewModel>(
                builder: (context, vm, _) {
                  final tasks = vm.tasks;
                  final urgent = tasks
                      .where((t) => t.priority == Priority.urgent)
                      .length;
                  final high = tasks
                      .where((t) => t.priority == Priority.high)
                      .length;
                  final medium = tasks
                      .where((t) => t.priority == Priority.medium)
                      .length;
                  final low = tasks
                      .where((t) => t.priority == Priority.low)
                      .length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preview thông báo:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '📋 Tổng quan công việc hôm nay',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      if (urgent > 0) Text('🔴 Khẩn cấp: $urgent task'),
                      if (high > 0) Text('🟠 Cao: $high task'),
                      if (medium > 0) Text('🔵 Trung bình: $medium task'),
                      if (low > 0) Text('🟢 Thấp: $low task'),
                      if (urgent + high + medium + low == 0)
                        const Text('Không có task nào hôm nay 🎉'),
                    ],
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

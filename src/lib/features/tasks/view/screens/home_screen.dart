import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/notification_time_picker.dart';
import '../../model/task_model.dart';
import '../../viewmodel/task_viewmodel.dart';
import '../widgets/task_widgets.dart';
import 'create_task_screen.dart';
import 'package:task_management_app/features/tasks/service/notif_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_management_app/features/statistics/viewmodel/statistics_viewmodel.dart';
import 'package:task_management_app/features/chatbot/view/widgets/user_avatar.dart';
import 'package:task_management_app/features/user/viewmodel/user_profile_viewmodel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _filterExpanded = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    bool isGranted = await NotifService().requestNotificationPermission();
    if (!isGranted) {
      print("User từ chối nhận thông báo rồi bro ơi!");
    }
  }

  Future<void> _refreshStatistics() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await context.read<StatisticsViewmodel>().getStatisticsData(userId);
  }

  Future<void> _openCreateTask(BuildContext context) async {
    final createdDate = await Navigator.push<DateTime>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
    );

    if (!mounted) return;

    if (createdDate != null) {
      context.read<TaskViewModel>().setDate(createdDate);
      await context.read<TaskViewModel>().fetchTasks();
      await _refreshStatistics();
      _showSuccessToast(context);
    }
  }

  void _showSuccessToast(BuildContext context) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        backgroundColor: theme.colorScheme.surface,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Icon(Icons.check_circle, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Đã tạo task thành công',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _toggleFilter() {
    setState(() => _filterExpanded = !_filterExpanded);
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEEE, d MMMM').format(DateTime.now());
    final viewModel = context.watch<TaskViewModel>();
    final profileVm = context.watch<UserProfileViewModel>();
    final theme = Theme.of(context);

    Map<Priority, List<TaskModel>> grouped = {};
    for (var priority in Priority.values.reversed) {
      final tasks = viewModel.tasks
          .where((t) => t.priority == priority)
          .toList();
      if (tasks.isNotEmpty) grouped[priority] = tasks;
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 250,
            child: ClipPath(
              clipper: TopWaveClipper(),
              child: Container(color: theme.colorScheme.primary),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.menu_rounded,
                        color: theme.colorScheme.onPrimary,
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const NotificationTimePicker(),
                            ),
                            child: Icon(
                              Icons.notifications_none_rounded,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 15),
                          UserAvatar(
                            size: 40,
                            avatarUrl: profileVm.user?.avatarUrl,
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: Icon(
                              Icons.add_rounded,
                              color: theme.colorScheme.onPrimary,
                            ),
                            onPressed: () => _openCreateTask(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Task',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Today',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 10,
                            itemBuilder: (context, index) {
                              DateTime date = DateTime.now().add(
                                Duration(days: index),
                              );
                              return GestureDetector(
                                onTap: () {
                                  // Khi bấm vào thì gọi hàm setDate để báo cho ViewModel biết
                                  viewModel.setDate(date);
                                },
                                child: DateBox(
                                  date: date,
                                  // Kiểm tra xem ngày của ô này có khớp với ngày đang được chọn trong ViewModel không
                                  isSelected: date.day == viewModel.selectedDate.day &&
                                              date.month == viewModel.selectedDate.month &&
                                              date.year == viewModel.selectedDate.year,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _toggleFilter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: _filterExpanded
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tune,
                                    size: 16,
                                    color: _filterExpanded
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Text(
                                      _filterExpanded ? 'Priority' : 'Filter',
                                      key: ValueKey(_filterExpanded),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _filterExpanded
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  AnimatedRotation(
                                    turns: _filterExpanded ? 0.5 : 0.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      Icons.expand_more_rounded,
                                      size: 18,
                                      color: _filterExpanded
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          _FilterChip(
                            label: 'All',
                            isSelected: viewModel.filterPriority == null,
                            color: theme.colorScheme.primary,
                            onTap: () => viewModel.setFilterPriority(null),
                          ),
                        ],
                      ),

                      // Các chip priority — hiện khi mở filter
                      ClipRect(
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          alignment: Alignment.topLeft,
                          child: ConstrainedBox(
                            constraints: _filterExpanded
                                ? const BoxConstraints()
                                : const BoxConstraints(maxHeight: 0),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: _filterExpanded ? 1 : 0,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: Priority.values
                                      .map(
                                        (p) => _FilterChip(
                                          label: p.label,
                                          isSelected: viewModel.filterPriority == p,
                                          color: p.color,
                                          onTap: () =>
                                              viewModel.setFilterPriority(p),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ─── Task List ────────────────────────────────
                Expanded(
                  child: grouped.isEmpty
                      ? _buildEmptyState(context)
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: grouped.entries.map((entry) {
                            final priority = entry.key;
                            final tasks = entry.value;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 10,
                                    top: 5,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 4,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: priority.color,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _priorityGroupLabel(priority),
                                            style: theme.textTheme.titleSmall,
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${tasks.length} task',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...tasks.map(
                                  (task) => AnimatedTaskCard(
                                    task: task,
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: priority.color.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        priority.icon,
                                        color: priority.color,
                                        size: 22,
                                      ),
                                    ),
                                    onQuickComplete: () async {
                                      await viewModel.updateTask(
                                        task.id,
                                        {'status': 1},
                                      );
                                      await _refreshStatistics();
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.menu_rounded, color: Colors.black),
          Row(
            children: [
              const Icon(Icons.notifications_none_rounded, color: Colors.black),
              const SizedBox(width: 15),
              UserAvatar(
                size: 40,
                avatarUrl: context.watch<UserProfileViewModel>().user?.avatarUrl,
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.add_rounded, color: Colors.black),
                onPressed: () => _openCreateTask(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _priorityGroupLabel(Priority priority) {
    switch (priority) {
      case Priority.urgent:
        return 'Ưu tiên Khẩn cấp';
      case Priority.high:
        return 'Ưu tiên Cao';
      case Priority.medium:
        return 'Ưu tiên Trung bình';
      case Priority.low:
        return 'Ưu tiên Thấp';
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checklist_rounded, size: 60, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'Chưa có task nào',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Nhấn + để tạo task mới',
            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Chip Widget ──────────────────────────────────────
// Đã xóa chữ 'void' trước StatelessWidget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? theme.colorScheme.onPrimary : color,
          ),
        ),
      ),
    );
  }
}
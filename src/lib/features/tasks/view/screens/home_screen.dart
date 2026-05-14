import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/notification_time_picker.dart';
import '../../model/task_model.dart';
import '../../viewmodel/task_viewmodel.dart';
import '../widgets/task_widgets.dart';
import 'create_task_screen.dart';
import 'package:task_management_app/features/category/model/category_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _filterExpanded = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleFilter() {
    setState(() => _filterExpanded = !_filterExpanded);
    if (_filterExpanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEEE, d MMMM').format(DateTime.now());
    final viewModel = context.watch<TaskViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              child: Container(color: AppColors.primaryBlue),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header ───────────────────────────────────
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
                        color: isDark
                            ? Theme.of(context).colorScheme.surface
                            : Colors.black,
                      ),
                      Row(
                        children: [
                          // ─── Nút chuông mở Notification Picker ───
                          GestureDetector(
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const NotificationTimePicker(),
                            ),
                            child: Icon(
                              Icons.notifications_none_rounded,
                              color: isDark
                                  ? Theme.of(context).colorScheme.surface
                                  : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 15),
                          const CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(
                              'https://i.pravatar.cc/150?u=user1',
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: Icon(
                              Icons.add_rounded,
                              color: isDark
                                  ? Theme.of(context).colorScheme.surface
                                  : Colors.black,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateTaskScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ─── Date Card ────────────────────────────────
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: isDark
                        ? Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          )
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Task',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Today',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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

                // ─── Filter Bar ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Nút Filter
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
                                    ? AppColors.primaryBlue
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primaryBlue,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.sort,
                                size: 16,
                                color: _filterExpanded
                                    ? Colors.white
                                    : AppColors.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Chip "All" luôn hiển thị
                          _FilterChip(
                            label: 'All',
                            isSelected: viewModel.filterPriority == null,
                            color: AppColors.primaryBlue,
                            onTap: () => viewModel.setFilterPriority(null),
                          ),
                        ],
                      ),

                      // Các chip priority — hiện khi mở filter
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: SizeTransition(
                          sizeFactor: _fadeAnim,
                          axisAlignment: -1,
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
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ─── Task List ────────────────────────────────
                Expanded(
                  child: grouped.isEmpty
                      ? _buildEmptyState() // Đã thêm '_' để gọi đúng hàm
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
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${tasks.length} task',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.grayText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...tasks.map(
                                  (task) => TaskCard(
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
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            );
                          }).toList(),
                        ),
                ),
              ], // Đóng children của Column
            ), // Đóng Column
          ), // Đóng SafeArea
        ], // Đóng children của Stack
      ), // Đóng Stack
    ); // Đóng Scaffold
  } // Đóng hàm build

  // --- Widget nhỏ tách ra cho sạch code ---

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
              const CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=user1'),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.add_rounded, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Bọc cái ChangeNotifierProvider ở ngay cửa ngõ để cấp Wi-Fi cho màn hình mới
                      builder: (ctx) => ChangeNotifierProvider(
                        create: (_) => CreateTaskProvider(), // Lưu ý cần import CreateTaskProvider nếu chưa có
                        child: const CreateTaskScreen(),
                      ),
                    ),
                  ).then((_) => context.read<TaskViewModel>().fetchTasks());
                },
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

  // Đã thêm dấu "_" vào trước tên hàm
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checklist_rounded, size: 60, color: AppColors.grayText),
          SizedBox(height: 12),
          Text(
            'Chưa có task nào',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.grayText,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Nhấn + để tạo task mới',
            style: TextStyle(fontSize: 13, color: AppColors.grayText),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}
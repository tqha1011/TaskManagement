import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../model/task_model.dart';
import '../../viewmodel/task_viewmodel.dart';
import '../widgets/task_widgets.dart';
import 'create_task_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEEE, d MMMM').format(DateTime.now());
    final viewModel = context.watch<TaskViewModel>();

    // Nhóm task theo priority
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
                      const Icon(Icons.menu_rounded, color: Colors.black),
                      Row(
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.black,
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
                            icon: const Icon(
                              Icons.add_rounded,
                              color: Colors.black,
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
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
                              style: const TextStyle(
                                color: AppColors.grayText,
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
                              return DateBox(
                                date: date,
                                isSelected: index == 0,
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
                  child: Row(
                    children: [
                      // Sort button
                      GestureDetector(
                        onTap: () => viewModel.toggleSortByPriority(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: viewModel.sortByPriority
                                ? AppColors.primaryBlue
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primaryBlue,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.sort,
                                size: 16,
                                color: viewModel.sortByPriority
                                    ? Colors.white
                                    : AppColors.primaryBlue,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Sort',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: viewModel.sortByPriority
                                      ? Colors.white
                                      : AppColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Filter theo priority
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // Chip "All"
                              _FilterChip(
                                label: 'All',
                                isSelected: viewModel.filterPriority == null,
                                color: AppColors.primaryBlue,
                                onTap: () => viewModel.setFilterPriority(null),
                              ),
                              const SizedBox(width: 8),
                              // Chip cho từng priority
                              ...Priority.values.map(
                                (p) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _FilterChip(
                                    label: p.label,
                                    isSelected: viewModel.filterPriority == p,
                                    color: p.color,
                                    onTap: () => viewModel.setFilterPriority(p),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ─── Task List nhóm theo Priority ─────────────
                Expanded(
                  child: grouped.isEmpty
                      ? _buildEmptyState()
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: grouped.entries.map((entry) {
                            final priority = entry.key;
                            final tasks = entry.value;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header nhóm
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

                                // Danh sách task trong nhóm
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
              ],
            ),
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

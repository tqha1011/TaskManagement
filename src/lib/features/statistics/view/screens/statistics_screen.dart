import 'package:flutter/material.dart';
import 'package:task_management_app/features/category/viewmodel/category_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/statistics_viewmodel.dart';
import '../widgets/statistics_widgets.dart';
import 'package:task_management_app/features/chatbot/view/widgets/user_avatar.dart';
import 'package:task_management_app/features/user/viewmodel/user_profile_viewmodel.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {

  int _selectedDayIndex = DateTime.now().weekday - 1;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        context.read<StatisticsViewmodel>().getStatisticsData(userId);
        final categoryViewModel = context.read<CategoryViewModel>();
        if (categoryViewModel.categories.isEmpty) {
          categoryViewModel.loadCategories();
        }
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileVm = context.watch<UserProfileViewModel>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF08142D), Color(0xFF0B1A38), Color(0xFF0A1834)],
                )
              : null,
        ),
        child: Consumer<StatisticsViewmodel>(
          builder: (context, viewModel, child) {

          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("Lỗi: ${viewModel.errorMessage}", textAlign: TextAlign.center),
              ),
            );
          }

          final data = viewModel.statisticsData;
          if (data == null) return const Center(child: Text("Không có dữ liệu"));

          final currentTasks = data.recentTasks;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // --- Header ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            UserAvatar(
                              size: 44,
                              avatarUrl: profileVm.user?.avatarUrl,
                            ),
                            const SizedBox(width: 15),
                            Text(
                              'Thống kê',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),


                  DailyProgressCard(
                    total: data.today.total,
                    completed: data.today.completed,
                    percentage: data.todayCompletedPercentage,
                  ),
                  const SizedBox(height: 25),

                  WeeklyChartCard(
                    selectedIndex: _selectedDayIndex,
                    thisWeekTotal: data.thisWeekTotal,
                    growthPercentage: data.growthPercentage,
                    weeklyHeights: viewModel.weeklyBarHeights,
                    onDaySelected: (index) {
                      setState(() {
                        _selectedDayIndex = index;
                      });
                    },
                  ),
                  const SizedBox(height: 30),


                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hoàn thành gần đây',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      Text(
                        'Xem tất cả',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      ],
                    ),
                    const SizedBox(height: 15),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: currentTasks.isEmpty
                        ? Container(
                            key: const ValueKey('empty_state'),
                            padding: const EdgeInsets.all(30),
                            alignment: Alignment.center,
                            child: Text(
                              'Chưa có công việc nào hoàn thành gần đây.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Column(
                      key: ValueKey('list_$_selectedDayIndex'),
                      children: currentTasks.map((task) {
                        return CompletedTaskCard(
                          task: task,
                          icon: Text(task.avatar ?? '📝', style: const TextStyle(
                              fontSize: 24,
                              color: null
                            )
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
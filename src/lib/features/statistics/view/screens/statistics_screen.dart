import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/statistics_viewmodel.dart';
import '../widgets/statistics_widgets.dart';

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
      }
    });
  }


  Icon _getIconForCategory(BuildContext context, String category) {
    switch (category) {
      case 'Design':
        return Icon(
          Icons.checklist_rtl_rounded,
          color: Theme.of(context).colorScheme.primary,
        );
      case 'Research': return const Icon(Icons.timer_outlined, color: Color(0xFFE67E22));
      case 'Development': return const Icon(Icons.calendar_month_outlined, color: Color(0xFF9B59B6));
      default: return const Icon(Icons.task_alt_rounded, color: Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<StatisticsViewmodel>(
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
                      const Row(
                        children: [
                          CircleAvatar(
                              radius: 22,
                              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=a042581f4e29026704d')
                          ),
                          SizedBox(width: 15),
                          Text('Thống kê', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
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
                      const Text('Hoàn thành gần đây', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
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
                      child: Text('Chưa có công việc nào hoàn thành gần đây.',
                          style: TextStyle(color: Colors.grey.shade500), textAlign: TextAlign.center),
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
    );
  }
}
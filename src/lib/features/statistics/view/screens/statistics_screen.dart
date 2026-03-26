import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../tasks/model/task_model.dart';
import '../../viewmodel/statistics_viewmodel.dart';
import '../widgets/statistics_widgets.dart';
import 'package:provider/provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {

  int _selectedDayIndex = 2;


  late Map<int, List<TaskModel>> _tasksByDay;

  @override
  void initState() {
    super.initState();
    // automatically call api when app started
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        context.read<StatisticsViewmodel>().getStatisticsData(userId);
      }
    });
  }


  Icon _getIconForCategory(String category) {
    switch (category) {
      case 'Design': return const Icon(Icons.checklist_rtl_rounded, color: AppColors.primaryBlue);
      case 'Research': return const Icon(Icons.timer_outlined, color: Color(0xFFE67E22));
      case 'Development': return const Icon(Icons.calendar_month_outlined, color: Color(0xFF9B59B6));
      default: return const Icon(Icons.task_alt_rounded, color: Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {

    List<TaskModel> currentTasks = _tasksByDay[_selectedDayIndex] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Consumer<StatisticsViewmodel>(
        builder: (context,viewModel,child){
          if(viewModel.isLoading){
            return const Center(child: CircularProgressIndicator());
          }

          if(viewModel.errorMessage != null){
            return Center(child: Text("Lỗi: ${viewModel.errorMessage}"));
          }

          final data = viewModel.statisticsData;
          if(data == null) return const Center(child: Text("Không có dữ liệu"));
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          CircleAvatar(radius: 22, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=a042581f4e29026704d')),
                          SizedBox(width: 15),
                          Text('Thống kê', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.notifications_none_rounded, color: AppColors.primaryBlue),
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

                  // Truyền State vào WeeklyChartCard
                  WeeklyChartCard(
                    selectedIndex: _selectedDayIndex,
                    onDaySelected: (index) {
                      setState(() {
                        _selectedDayIndex = index; // Cập nhật lại UI khi chọn ngày khác
                      });
                    },
                  ),
                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Hoàn thành gần đây', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                      Text('Xem tất cả', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Render Task with animation
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: currentTasks.isEmpty
                        ? Container(
                      key: ValueKey('empty_$_selectedDayIndex'),
                      padding: const EdgeInsets.all(30),
                      alignment: Alignment.center,
                      child: Text('Không có công việc nào hoàn thành vào ngày này.',
                          style: TextStyle(color: Colors.grey.shade500), textAlign: TextAlign.center),
                    )
                        : Column(
                      key: ValueKey('list_$_selectedDayIndex'),
                      children: currentTasks.map((task) {
                        return CompletedTaskCard(
                          task: task,
                          icon: _getIconForCategory(task.category),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}
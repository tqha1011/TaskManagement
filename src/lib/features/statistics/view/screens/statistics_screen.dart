import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../tasks/model/task_model.dart';
import '../widgets/statistics_widgets.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // Variable to store the currently selected day on the chart (0 = Mon, 1 = Tue, 2 = Wed...)
  int _selectedDayIndex = 2; // Default select Wed (Index 2) like in the design

  // Mock data categorized by day (0 to 6)
  late Map<int, List<TaskModel>> _tasksByDay;

  @override
  void initState() {
    super.initState();
    // Create mock data for a few days for testing
    _tasksByDay = {
      0: [ // Thứ 2
        TaskModel(id: 'stat_t2_1', title: 'Họp team đầu tuần', description: 'Lên kế hoạch Sprint mới.', category: 'Development', startTime: const TimeOfDay(hour: 9, minute: 0), endTime: const TimeOfDay(hour: 10, minute: 0), date: DateTime.now()),
      ],
      1: [ // Thứ 3
        TaskModel(id: 'stat_t3_1', title: 'Fix bug UI', description: 'Sửa lỗi hiển thị trên iOS.', category: 'Development', startTime: const TimeOfDay(hour: 14, minute: 0), endTime: const TimeOfDay(hour: 16, minute: 0), date: DateTime.now()),
        TaskModel(id: 'stat_t3_2', title: 'Đọc tài liệu Flutter', description: 'Nghiên cứu State Management.', category: 'Research', startTime: const TimeOfDay(hour: 20, minute: 0), endTime: const TimeOfDay(hour: 21, minute: 0), date: DateTime.now()),
      ],
      2: [ // Thứ 4 (Mặc định)
        TaskModel(id: 'stat_t4_1', title: 'Thiết kế UI màn hình Dashboard', description: 'Hoàn thành bản thiết kế Figma.', category: 'Design', startTime: const TimeOfDay(hour: 10, minute: 30), endTime: const TimeOfDay(hour: 11, minute: 30), date: DateTime.now()),
        TaskModel(id: 'stat_t4_2', title: 'Học tiếng Anh - 30 phút', description: 'Ôn tập 50 từ vựng chuyên ngành IT qua Anki.', category: 'Research', startTime: const TimeOfDay(hour: 8, minute: 15), endTime: const TimeOfDay(hour: 8, minute: 45), date: DateTime.now()),
        TaskModel(id: 'stat_t4_3', title: 'Gửi báo cáo tuần cho sếp', description: 'Tổng hợp tiến độ dự án.', category: 'Development', startTime: const TimeOfDay(hour: 7, minute: 45), endTime: const TimeOfDay(hour: 8, minute: 0), date: DateTime.now()),
      ],
    };
  }

  // Hàm hỗ trợ chọn Icon dựa theo Category để UI sinh động hơn
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
    // Lấy danh sách task của ngày đang chọn (nếu không có thì trả về list rỗng)
    List<TaskModel> currentTasks = _tasksByDay[_selectedDayIndex] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
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

              const DailyProgressCard(),
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

              // Render danh sách Task kèm hiệu ứng đổi mới
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
      ),
    );
  }
}
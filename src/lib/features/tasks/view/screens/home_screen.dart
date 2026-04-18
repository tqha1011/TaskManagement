import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Đảm bảo đã import Supabase
import '../../../../core/theme/app_colors.dart';
import '../../model/task_model.dart';
import '../../viewmodel/task_viewmodel.dart';
import '../widgets/task_widgets.dart';
import 'create_task_screen.dart';
import 'package:task_management_app/features/category/model/category_model.dart';

// ==========================================
// 1. STATE MANAGEMENT LOGIC (Giữ logic Supabase của bạn)
// ==========================================
/*class TaskProvider extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;
  
  List<Map<String, dynamic>> _allTasks = [];
  Priority? _filterPriority; // Thêm filter logic
  Priority? get filterPriority => _filterPriority;

  Future<void> fetchTasks() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    if (user == null) return; 

    try {
      final data = await supabase
          .from('task')
          .select('*')
          .eq('profile_id', user.id) 
          .order('create_at', ascending: true);
      
      if (data != null) {
        _allTasks = List<Map<String, dynamic>>.from(data);
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Lỗi lấy task: $e");
    }
  }

  // Logic lọc Task theo ngày VÀ theo Priority chip
  List<Map<String, dynamic>> get filteredTasks {
    if (_allTasks.isEmpty) return [];

    return _allTasks.where((task) {
      if (task['create_at'] == null) return false;
      try {
        DateTime taskDate = DateTime.parse(task['create_at'].toString());
        bool matchesDate = taskDate.day == _selectedDate.day &&
               taskDate.month == _selectedDate.month &&
               taskDate.year == _selectedDate.year;
        
        // --- LOGIC LỌC ĐÃ ĐƯỢC FIX ---
        if (_filterPriority != null) {
          // Quy đổi Priority đang chọn ra số (giống hệt lúc insert vào DB)
          int filterId = 3; // Medium
          if (_filterPriority!.label.toLowerCase() == 'urgent') filterId = 1;
          else if (_filterPriority!.label.toLowerCase() == 'high') filterId = 2;
          else if (_filterPriority!.label.toLowerCase() == 'low') filterId = 4;

          // So sánh số trong DB với số đang chọn
          return matchesDate && task['priority'] == filterId;
        }
        
        return matchesDate;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setFilterPriority(Priority? p) {
    _filterPriority = p;
    notifyListeners();
  }
}*/

// ==========================================
// 2. UI SCREEN (Merge UI mới vào Logic cũ)
// ==========================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TaskViewModel()..fetchTasks(),
      child: Scaffold(
        body: Builder(
          builder: (innerContext) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            
            return Stack(
              children: [
                // --- BACKGROUND WAVE ---
                Positioned(
                  top: 0, left: 0, right: 0, height: 250,
                  child: ClipPath(
                    clipper: TopWaveClipper(), 
                    child: Container(color: AppColors.primaryBlue)
                  ),
                ),
                
                SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- APP BAR ---
                      _buildAppBar(innerContext, isDark),
                      
                      const SizedBox(height: 10),
                      
                      // --- CALENDAR CARD ---
                      _buildCalendarCard(context),

                      const SizedBox(height: 15),
                      
                      // --- FILTER BAR (Giữ từ bản UI mới) ---
                      _buildFilterBar(innerContext),

                      const SizedBox(height: 10),
                      
                      // --- TASK LIST (Nhóm theo Priority từ bản UI mới) ---
                      Expanded(
                        child: Consumer<TaskViewModel>(
                          builder: (context, provider, child) {
                            final tasks = provider.tasks;
                            if (tasks.isEmpty) return _buildEmptyState();

                            // Logic grouping tasks
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: tasks.length,
                              itemBuilder: (context, index) {
                                final item = tasks[index];
                                return _buildTaskItem(item, index);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }

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
                        create: (_) => CreateTaskProvider(), 
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

  Widget _buildCalendarCard(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Task', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 5),
            Consumer<TaskViewModel>(
              builder: (context, provider, child) {
                String formattedDate = DateFormat('EEEE, d MMMM').format(provider.selectedDate);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Today', style: Theme.of(context).textTheme.titleMedium),
                    Text(formattedDate, style: const TextStyle(color: AppColors.grayText, fontSize: 14)),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 80,
              child: Consumer<TaskViewModel>(
                builder: (context, provider, child) {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 14,
                    itemBuilder: (context, index) {
                      DateTime date = DateTime.now().add(Duration(days: index));
                      bool isSelected = date.day == provider.selectedDate.day &&
                                        date.month == provider.selectedDate.month &&
                                        date.year == provider.selectedDate.year;
                      return GestureDetector(
                        onTap: () => provider.setDate(date),
                        child: DateBox(date: date, isSelected: isSelected),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final provider = context.watch<TaskViewModel>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'All',
              isSelected: provider.filterPriority == null,
              color: AppColors.primaryBlue,
              onTap: () => provider.setFilterPriority(null),
            ),
            const SizedBox(width: 8),
            ...Priority.values.map((p) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: p.label,
                isSelected: provider.filterPriority == p,
                color: p.color,
                onTap: () => provider.setFilterPriority(p),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(TaskModel item, int index) {
    DateTime dt = item.date != null 
        ? DateTime.parse(item.date.toString()) 
        : DateTime.now();

    // Ánh xạ priority từ database
    final priority = _mapPriority(item.priority?.toString());

    final taskModel = TaskModel(
      id: item.id?.toString() ?? index.toString(),
      title: item.title ?? 'No Title',
      description: item.description ?? 'No Description',
      category: const CategoryModel(
        id: 0, 
        name: 'General',
        colorCode: '#5A8DF3', // Lấy luôn màu mặc định từ hàm của ông cho tông xuyệt tông
        profileId: '',
      ),
      startTime: TimeOfDay.fromDateTime(dt),
      endTime: TimeOfDay.fromDateTime(dt.add(const Duration(hours: 1))),
      date: dt,
      priority: priority, // Truyền priority vào model
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0), // Cách các task ra một chút cho đẹp
      child: TaskCard(
        task: taskModel,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: priority.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15)
          ),
          child: Icon(priority.icon, color: priority.color),
        ),
        // TRUYỀN CÁI NHÃN VÀO ĐÂY NÈ ÔNG:
        trailing: _buildPriorityBadge(priority), 
      ),
    );
  }

// Hàm vẽ cái nhãn Priority nhỏ xinh (Thêm hàm này vào class HomeScreen luôn)
Widget _buildPriorityBadge(Priority priority) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: priority.color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: priority.color.withOpacity(0.5), width: 1),
    ),
    child: Text(
      priority.label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: priority.color,
      ),
    ),
  );
}

  Priority _mapPriority(String? p) {
    // Database của ông giờ đang lưu số (1, 2, 3, 4)
    switch (p) {
      case '1': return Priority.urgent;
      case '2': return Priority.high;
      case '3': return Priority.medium;
      case '4': return Priority.low;
      
      // Khúc này tui để dự phòng, lỡ trong DB ông còn sót mấy cái task cũ lưu bằng chữ
      case 'urgent': return Priority.urgent;
      case 'high': return Priority.high;
      case 'low': return Priority.low;
      default: return Priority.medium;
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('Không có task nào hết!', style: TextStyle(color: AppColors.grayText)),
    );
  }
}

// --- Filter Chip Component ---
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.color, required this.onTap});

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
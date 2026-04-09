import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../model/task_model.dart';
import '../widgets/task_widgets.dart'; // Chứa TopWaveClipper, DateBox, TaskCard
import '../../../main/view/screens/create_task.dart';


// ==========================================
// 1. STATE MANAGEMENT LOGIC
// ==========================================
class TaskProvider extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  List<Map<String, dynamic>> _allTasks = [];

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
      debugPrint("Lỗi lấy task thật của Kiệt: $e");
    }
  }

  List<Map<String, dynamic>> get filteredTasks {
    if (_allTasks.isEmpty) return [];

    return _allTasks.where((task) {
      if (task['create_at'] == null) return false;
      try {
        DateTime taskDate = DateTime.parse(task['create_at'].toString());
        return taskDate.day == _selectedDate.day &&
               taskDate.month == _selectedDate.month &&
               taskDate.year == _selectedDate.year;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
}

// ==========================================
// 2. GIAO DIỆN CHÍNH (Giữ nguyên UI của bé)
// ==========================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TaskProvider()..fetchTasks(),
      child: Scaffold(
        body: Builder(
          builder: (innerContext) { // Dùng innerContext để Provider hoạt động chuẩn xác
            return Stack(
              children: [
                // --- SÓNG XANH Ở TRÊN (UI cũ của mày) ---
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
                      Padding(
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
                                    // Chỗ này đã fix lỗi đỏ lè bằng cách bọc Provider cho màn hình mới
                                    Navigator.push(
                                      innerContext,
                                      MaterialPageRoute(
                                        builder: (context) => ChangeNotifierProvider(
                                          create: (context) => CreateTaskProvider(), // Cần import file chứa class này
                                          child: const CreateTaskScreen(),
                                        ),
                                      ),
                                    ).then((_) {
                                      // Quay lại thì load data mới
                                      if (innerContext.mounted) {
                                        innerContext.read<TaskProvider>().fetchTasks();
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // --- BOX CHỨA LỊCH ---
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                        child: Padding(
                          padding: const EdgeInsets.all(25.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('My Task', style: Theme.of(context).textTheme.headlineMedium),
                              const SizedBox(height: 5),
                              
                              // Row hiển thị Ngày Tháng chạy bằng data thật
                              Consumer<TaskProvider>(
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
                              
                              // Thanh kéo ngang Lịch
                              SizedBox(
                                height: 80,
                                child: Consumer<TaskProvider>(
                                  builder: (context, provider, child) {
                                    return ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: 30, // Hiện 30 ngày
                                      itemBuilder: (context, index) {
                                        DateTime date = DateTime.now().add(Duration(days: index));
                                        bool isSelected = 
                                            date.day == provider.selectedDate.day &&
                                            date.month == provider.selectedDate.month &&
                                            date.year == provider.selectedDate.year;

                                        return GestureDetector(
                                          onTap: () => provider.setDate(date),
                                          child: AbsorbPointer( // Bọc cái này để DateBox không nuốt sự kiện tap
                                            child: DateBox(date: date, isSelected: isSelected),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      // --- DANH SÁCH TASK TỪ DATA THẬT ---
                      Expanded(
                        child: Consumer<TaskProvider>(
                          builder: (context, provider, child) {
                            final tasks = provider.filteredTasks;

                            if (tasks.isEmpty) {
                              return const Center(
                                child: Text('Không có task nào hết Kiệt ơi!', style: TextStyle(color: AppColors.grayText)),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: tasks.length,
                              itemBuilder: (context, index) {
                                final item = tasks[index];
                                
                                // Xử lý thời gian
                                DateTime dt = DateTime.now();
                                if (item['create_at'] != null) {
                                  dt = DateTime.parse(item['create_at'].toString());
                                }

                                // Map dữ liệu từ Supabase thành TaskModel của mày
                                final taskModel = TaskModel(
                                  id: item['id']?.toString() ?? index.toString(),
                                  title: item['title'] ?? 'No Title',
                                  description: 'Ưu tiên: ${item['priority'] ?? 'Bình thường'}',
                                  category: 'General', 
                                  startTime: TimeOfDay.fromDateTime(dt),
                                  endTime: TimeOfDay.fromDateTime(dt.add(const Duration(hours: 1))), // Giả lập +1 tiếng
                                  date: dt,
                                );

                                // Bỏ vào TaskCard xịn xò của mày
                                return TaskCard(
                                  task: taskModel,
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: const Color(0xFFF1F7FD), borderRadius: BorderRadius.circular(15)),
                                    child: const Icon(Icons.circle_outlined, color: AppColors.primaryBlue),
                                  ),
                                );
                              },
                            );
                          }
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
}
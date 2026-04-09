import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import 'create_task.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- State Management ---


class TaskProvider extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  List<Map<String, dynamic>> _allTasks = [];

  Future<void> fetchTasks() async {
    final supabase = Supabase.instance.client;
    
    // Lấy ID của thằng đang đăng nhập nè
    final user = supabase.auth.currentUser;
    if (user == null) return; 

    try {
      // Gọi DB thật với profile_id chính chủ
      final data = await supabase
          .from('task')
          .select('*')
          .eq('profile_id', user.id) // Filter theo đúng ID của mày
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

// --- Main Screen ---
class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TaskProvider()..fetchTasks(),
      child: Scaffold(
        backgroundColor: AppColors.primary, // Phần top bar màu xanh
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 30),
                        Text(
                          "My Task",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Today", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("Saturday, 21 March", style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                        SizedBox(height: 20),
                        _buildCalendar(),
                        SizedBox(height: 30),
                        Expanded(child: _buildTaskList()),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) { // Thêm context vào tham số nếu cần
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.menu, color: Colors.black),
          Row(
            children: [
              Icon(Icons.notifications_none, color: Colors.black),
              SizedBox(width: 15),
              CircleAvatar(
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=kiet'),
              ),
              SizedBox(width: 15),
              // Sửa chỗ này nè:
              // Sửa chỗ này nè:
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(       // <-- Bơm Provider vào route mới
                        create: (context) => CreateTaskProvider(),        // <-- Khởi tạo Provider
                        child: const CreateTaskScreen(),                  // <-- Gắn màn hình vào làm child
                      ),
                    ),
                  ).then((_) {
                    // Sau khi pop từ màn hình CreateTaskScreen về, 
                    // dòng này sẽ kích hoạt để load lại dữ liệu mới nhất
                    if (context.mounted) {
                      context.read<TaskProvider>().fetchTasks();
                    }
                  });
                },
                child: const Icon(Icons.add, color: Colors.black),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        // Lấy ngày hôm nay làm mốc
        DateTime today = DateTime.now();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(100, (index) {
              // Tự động tính ngày tiếp theo bằng cách cộng thêm index ngày
              DateTime date = today.add(Duration(days: index));
              
              // Format thứ (SAT, SUN...), ngày (21, 22...)
              String weekday = DateFormat('E').format(date).toUpperCase(); 
              String dayNumber = DateFormat('d').format(date);
              
              // So sánh ngày đang render có trùng với ngày đang chọn không
              bool isSelected = 
                  date.day == provider.selectedDate.day &&
                  date.month == provider.selectedDate.month &&
                  date.year == provider.selectedDate.year;

              return GestureDetector(
                onTap: () => provider.setDate(date), // Lưu cả cụm ngày tháng năm
                child: Container(
                  margin: const EdgeInsets.only(right: 15),
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryBlue : AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      if (!isSelected) const BoxShadow(color: Colors.black12, blurRadius: 5)
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        dayNumber,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        weekday,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  
  Widget _buildTaskList() {
  return Consumer<TaskProvider>(
    builder: (context, provider, child) {
      final tasks = provider.filteredTasks;

      if (tasks.isEmpty) {
        return Center(
          child: Text(
            "Không có task nào hết Kiệt ơi!",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        );
      }

      return ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final item = tasks[index];
          
          // Xử lý thời gian an toàn
          String formattedTime = "--:--";
          if (item['create_at'] != null) {
            DateTime dt = DateTime.parse(item['create_at'].toString());
            formattedTime = DateFormat('hh:mm a').format(dt);
          }
          
          return _taskItem(
            item['title'] ?? 'No Title', 
            "Ưu tiên: ${item['priority'] ?? 'Bình thường'}", 
            formattedTime, 
            false 
          );
        },
      );
    },
  );
}

  Widget _taskItem(String title, String desc, String time, bool hasImage) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(width: 15),
          if (hasImage) ...[
            CircleAvatar(radius: 20, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=meeting')),
            SizedBox(width: 15),
          ] else ...[
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.backgroundBlue, shape: BoxShape.circle),
              child: Icon(Icons.phone_outlined, color: AppColors.primaryBlue, size: 20),
            ),
            SizedBox(width: 15),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(desc, style: TextStyle(color: AppColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.timeBoxBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(time, style: TextStyle(color: Colors.white, fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
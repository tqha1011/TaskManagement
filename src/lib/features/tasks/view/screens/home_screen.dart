import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../model/task_model.dart'; // Đừng quên import TaskModel
import '../widgets/task_widgets.dart';
import 'create_task_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEEE, d MMMM').format(DateTime.now());

    // --- TẠO DỮ LIỆU GIẢ LẬP (MOCK DATA) ---
    final task1 = TaskModel(
      id: '1', // ID dùng để làm tag cho Hero Animation
      title: 'Team Meeting',
      description: 'Discuss all questions about new projects',
      category: 'Development',
      startTime: const TimeOfDay(hour: 10, minute: 0),
      endTime: const TimeOfDay(hour: 11, minute: 0),
      date: DateTime.now(),
    );

    final task2 = TaskModel(
      id: '2', // ID phải khác nhau
      title: 'Call the stylist',
      description: 'Agree on an evening look',
      category: 'Design',
      startTime: const TimeOfDay(hour: 11, minute: 0),
      endTime: const TimeOfDay(hour: 12, minute: 0),
      date: DateTime.now(),
    );
    // ----------------------------------------

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0, height: 250,
            child: ClipPath(clipper: TopWaveClipper(), child: Container(color: AppColors.primaryBlue)),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateTaskScreen())),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Today', style: Theme.of(context).textTheme.titleMedium),
                            Text(formattedDate, style: const TextStyle(color: AppColors.grayText, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 10,
                            itemBuilder: (context, index) {
                              DateTime date = DateTime.now().add(Duration(days: index));
                              return DateBox(date: date, isSelected: index == 0);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // --- SỬ DỤNG MOCK DATA VÀO TASKCARD ---
                      TaskCard(
                        task: task1, // Truyền task1 vào đây
                        leading: Stack(
                          children: [
                            const CircleAvatar(radius: 15, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=user2')),
                            const Positioned(left: 10, child: CircleAvatar(radius: 15, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=user3'))),
                            const Positioned(left: 20, child: CircleAvatar(radius: 15, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=user4'))),
                            Positioned(
                              left: 30,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.add_rounded, size: 20, color: AppColors.primaryBlue),
                              ),
                            )
                          ],
                        ),
                      ),
                      TaskCard(
                        task: task2, // Truyền task2 vào đây
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFF1F7FD), borderRadius: BorderRadius.circular(15)),
                          child: const Icon(Icons.call_outlined, color: AppColors.primaryBlue),
                        ),
                      ),
                      // ----------------------------------------
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
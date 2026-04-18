import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Adjust these import paths to match your project structure ---
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_input_field.dart';
import '../../model/task_model.dart';
import '../../viewmodel/task_viewmodel.dart';
import '../widgets/priority_selector.dart'; // Import 2 cục UI ở trên vào
//import '../widgets/tag_selector.dart';
import 'package:task_management_app/features/category/view/widgets/category_choice_chips.dart';
import 'package:task_management_app/features/category/viewmodel/category_viewmodel.dart';
import 'package:task_management_app/features/tag/view/widgets/tag_selector.dart';
import 'package:task_management_app/features/tag/viewmodel/tag_viewmodel.dart';

import '../../../../core/widgets/custom_input_field.dart';
import '../../model/task_model.dart';
import '../../viewmodel/task_viewmodel.dart';
import '../widgets/task_widgets.dart';
import '../widgets/priority_selector.dart';

// ============================================================================
// 1. STATE MANAGEMENT (PROVIDER) - Xử lý logic Supabase
// ============================================================================

class CreateTaskProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // --- UI State Variables ---
  String _selectedCategory = "Development";
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  bool _isLoading = false;

  // --- Getters ---
  String get selectedCategory => _selectedCategory;
  DateTime get selectedDate => _selectedDate;
  TimeOfDay get startTime => _startTime;
  TimeOfDay get endTime => _endTime;
  bool get isLoading => _isLoading;

  // --- Setters (Triggers UI Rebuild) ---
  void setCategory(String value) {
    _selectedCategory = value;
    notifyListeners();
  }

  void setDate(DateTime value) {
    _selectedDate = value;
    notifyListeners();
  }

  void setStartTime(TimeOfDay value) {
    _startTime = value;
    notifyListeners();
  }

  void setEndTime(TimeOfDay value) {
    _endTime = value;
    notifyListeners();
  }

  Future<void> submitTask(
  BuildContext context, {
  required String taskName,
  required String description,
  required dynamic priority,
  required List<dynamic> tags,
  required int? categoryId, // Thêm tham số ID từ UI truyền vào
}) async {
  if (taskName.trim().isEmpty) {
    _showSnackBar(context, "Task name is required.");
    return;
  }

  // Check xem có chọn Category chưa
  if (categoryId == null) {
    _showSnackBar(context, "Please select a category.");
    return;
  }

  final user = _supabase.auth.currentUser;
  if (user == null) {
    _showSnackBar(context, "Session not found. Please re-authenticate.");
    return;
  }

  _isLoading = true;
  notifyListeners();

  try {
    // 1. Xử lý Priority ID
    int priorityId = 3; // Mặc định Medium
    final String priorityStr = priority.toString().toLowerCase();

    if (priorityStr.contains('urgent')) {
      priorityId = 1;
    } else if (priorityStr.contains('high')) {
      priorityId = 2;
    } else if (priorityStr.contains('medium')) {
      priorityId = 3;
    } else if (priorityStr.contains('low')) {
      priorityId = 4;
    }

    // 2. Xử lý thời gian
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    // 3. Insert vào Supabase
    await _supabase.from('task').insert({
      'title': taskName.trim(),
      //'description': description.trim(), // Tui mở comment cái này ra cho ông luôn
      'status': 0,
      'priority': priorityId,
      'profile_id': user.id,
      'category_id': categoryId, // Dùng ID thực tế từ UI
      'create_at': scheduledDateTime.toIso8601String(),
    });

    if (context.mounted) {
      _showSnackBar(context, "Task created successfully.");
      // Chỉ để pop ở đây, bên ngoài UI ông xoá cái pop kia đi nhé
      Navigator.pop(context); 
    }
  } catch (e) {
    debugPrint("Data Persistence Error: $e");
    if (context.mounted) {
      _showSnackBar(context, "Database synchronization failed: $e");
    }
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================================================
// 2. USER INTERFACE (UI) - Màn hình tạo Task
// ============================================================================

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TextEditingController _nameController = TextEditingController(
    text: 'Team Meeting',
  );
  final TextEditingController _descController = TextEditingController(
    text: 'Discuss all questions about new projects',
  );
  

  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoryViewModel>().loadCategories();
      context.read<TagViewModel>().loadTags();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoryViewModel = context.watch<CategoryViewModel>();
    final tagViewModel = context.watch<TagViewModel>();
    String formattedDate = DateFormat('EEEE, d MMMM').format(context.read<CreateTaskProvider>().selectedDate);
    final categories = categoryViewModel.categories;

    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- Custom Header ---
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Icon(
                    Icons.menu_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  Icon(
                    Icons.assignment_outlined,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ],
              ),
            ),

            // ─── Body ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Task',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 25),

                    // Task Name
                    CustomInputField(
                      label: 'Task Name',
                      hint: 'Enter task name',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 20),

                    // Category
                    Text(
                      'Select Category',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      child: categories.isEmpty
                          ? Text(
                              categoryViewModel.isLoading
                                  ? 'Loading categories...'
                                  : 'No categories found',
                              style: Theme.of(context).textTheme.bodyMedium,
                            )
                          : CategoryChoiceChips(
                              categories: categories,
                              selectedCategoryId: _selectedCategoryId,
                              onSelected: (category) {
                                setState(() => _selectedCategoryId = category.id);
                              },
                            ),
                    ),
                    const SizedBox(height: 20),

                    // --- Gọi 2 Widget ông đã code ---
                    const PrioritySelector(),
                    const SizedBox(height: 20),
                    const TagSelector(),
                    const SizedBox(height: 20),

                    // --- Date ---
                    Consumer<CreateTaskProvider>(
                      builder: (context, provider, child) {
                        final formattedDate = DateFormat('EEEE, d MMMM')
                            .format(provider.selectedDate);
                            
                        return InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: provider.selectedDate,
                              firstDate: DateTime.now(), 
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              provider.setDate(picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Date', style: theme.textTheme.labelLarge),
                                    const SizedBox(height: 5),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          formattedDate,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Container(
                                          width: 150,
                                          height: 1,
                                          color: theme.colorScheme.outline,
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(
                                    Icons.date_range_rounded,
                                    color: Colors.white,
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 25),

                    //Clock
                    /*Row(
                      children: [
                        // --- Start Time ---
                        Expanded(
                          child: Consumer<CreateTaskProvider>(
                            builder: (context, provider, child) {
                              final formattedStartTime = provider.startTime.format(context);
                              return InkWell(
                                onTap: () async {
                                  final TimeOfDay? picked = await showTimePicker(
                                    context: context,
                                    initialTime: provider.startTime,
                                  );
                                  if (picked != null) {
                                    provider.setStartTime(picked);
                                  }
                                },
                                borderRadius: BorderRadius.circular(15),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Start Time', style: theme.textTheme.labelLarge),
                                            const SizedBox(height: 5),
                                            Text(
                                              formattedStartTime,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Container(height: 1, color: theme.colorScheme.outline),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.access_time_rounded, color: Colors.white, size: 20),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        const SizedBox(width: 20), // Khoảng cách giữa 2 cục thời gian
                        
                        // --- End Time ---
                        Expanded(
                          child: Consumer<CreateTaskProvider>(
                            builder: (context, provider, child) {
                              final formattedEndTime = provider.endTime.format(context);
                              return InkWell(
                                onTap: () async {
                                  final TimeOfDay? picked = await showTimePicker(
                                    context: context,
                                    initialTime: provider.endTime,
                                  );
                                  if (picked != null) {
                                    provider.setEndTime(picked);
                                  }
                                },
                                borderRadius: BorderRadius.circular(15),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('End Time', style: theme.textTheme.labelLarge),
                                            const SizedBox(height: 5),
                                            Text(
                                              formattedEndTime,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Container(height: 1, color: theme.colorScheme.outline),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 20),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),*/

                    // --- Input Desc ---
                    CustomInputField(
                      label: 'Description',
                      hint: 'Enter task description',
                      controller: _descController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 25),

                    // Description
                    CustomInputField(
                      label: 'Description',
                      hint: 'Enter task description',
                      controller: _descController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 40),

                    // ─── Create Button ────────────────────────
                    Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            // Kiểm tra loading để tránh user bấm liên tọi
                            if (context.read<CreateTaskProvider>().isLoading) return;

                            await context.read<CreateTaskProvider>().submitTask(
                              context,
                              taskName: _nameController.text,
                              description: _descController.text,
                              priority: context.read<TaskViewModel>().selectedPriority,
                              tags: List.from(context.read<TagViewModel>().selectedTags),
                              categoryId: _selectedCategoryId, // Truyền cái biến state ở UI vào đây
                            );

                            // Sau khi tạo xong, reset mấy cái linh tinh
                            if (mounted) {
                              context.read<TaskViewModel>().reset();
                              context.read<TagViewModel>().resetSelection();
                            }
                            
                            // KHÔNG dùng Navigator.pop(context) ở đây nữa vì trong Provider làm rồi.
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 100,
                              vertical: 15,
                            ),
                          ),
                          child: const Text('Create Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

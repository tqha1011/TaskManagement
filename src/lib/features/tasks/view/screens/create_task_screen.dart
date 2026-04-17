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
import '../widgets/tag_selector.dart';

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
  }) async {
    if (taskName.trim().isEmpty) {
      _showSnackBar(context, "Task name is required.");
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
      final categoryMapping = {
        "Development": 1,
        "Research": 2,
        "Design": 3,
        "Backend": 4,
      };
      final int categoryId = categoryMapping[_selectedCategory] ?? 1;

      int priorityId = 3;
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

      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      await _supabase.from('task').insert({
        'title': taskName.trim(),
        'status': 0,
        'priority': priorityId,
        'profile_id': user.id,
        'category_id': categoryId,
        'create_at': scheduledDateTime.toIso8601String(),
        // 'description': description.trim(), 
      });

      if (context.mounted) {
        _showSnackBar(context, "Task created successfully.");
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                    color: Colors.black.withOpacity(0.05),
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
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Icon(
                    Icons.menu_rounded,
                    color: theme.colorScheme.onSurface,
                  ),
                  Icon(
                    Icons.assignment_outlined,
                    color: theme.colorScheme.onSurface,
                  ),
                ],
              ),
            ),

            // --- Body ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Task',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // --- Input Name ---
                    CustomInputField(
                      label: 'Task Name',
                      hint: 'Enter task name',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 20),

                    // --- Category ---
                    Text('Select Category', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 10),
                    Consumer<CreateTaskProvider>(
                      builder: (context, provider, child) {
                        final List<String> categories = [
                          'Development', 'Research', 'Design', 'Backend'
                        ];
                        return SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              final isSelected = category == provider.selectedCategory;
                              
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: ChoiceChip(
                                  label: Text(category),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      provider.setCategory(category);
                                    }
                                  },
                                  backgroundColor: isDark
                                      ? theme.colorScheme.surfaceContainerHighest
                                      : const Color(0xFFF1F7FD),
                                  selectedColor: theme.colorScheme.primary,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : theme.colorScheme.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: isDark ? theme.colorScheme.outline : const Color(0xFFF1F7FD),
                                      width: 1,
                                    ),
                                  ),
                                  showCheckmark: false,
                                ),
                              );
                            },
                          ),
                        );
                      },
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

                    // --- Input Desc ---
                    CustomInputField(
                      label: 'Description',
                      hint: 'Enter task description',
                      controller: _descController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 40),

                    // --- Nút Submit ---
                    Consumer<CreateTaskProvider>(
                      builder: (context, provider, child) {
                        return Center(
                          child: ElevatedButton(
                            onPressed: provider.isLoading
                                ? null
                                : () {
                                    final viewModel = context.read<TaskViewModel>();

                                    provider.submitTask(
                                      context,
                                      taskName: _nameController.text,
                                      description: _descController.text,
                                      priority: viewModel.selectedPriority,
                                      tags: List.from(viewModel.selectedTags),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 100, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 2,
                            ),
                            child: provider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Create Task',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        );
                      },
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
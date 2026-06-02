import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_management_app/features/category/model/category_model.dart';

import '../../../../core/widgets/custom_input_field.dart';
import '../../model/task_model.dart';
import '../../viewmodel/task_viewmodel.dart';
import '../widgets/priority_selector.dart';
import '../widgets/task_widgets.dart';

import 'package:task_management_app/features/category/view/widgets/category_choice_chips.dart';
import 'package:task_management_app/features/category/viewmodel/category_viewmodel.dart';
import 'package:task_management_app/features/tag/view/widgets/tag_selector.dart';
import 'package:task_management_app/features/tag/viewmodel/tag_viewmodel.dart';

// ============================================================================
// 1. STATE MANAGEMENT (PROVIDER)
// ============================================================================
class CreateTaskProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // --- UI State Variables ---
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  bool _isRepeating = false;
  String _repeatType = 'daily';

  bool get isRepeating => _isRepeating;
  String get repeatType => _repeatType;
  bool _isLoading = false;

  void setRepeating(bool value) {
    _isRepeating = value;
    notifyListeners();
  }

  void setRepeatType(String value) {
    _repeatType = value;
    notifyListeners();
  }

  // --- Getters ---
  DateTime get selectedDate => _selectedDate;
  TimeOfDay get startTime => _startTime;
  TimeOfDay get endTime => _endTime;
  bool get isLoading => _isLoading;

  // --- Setters ---
  void setDate(DateTime value) {
    _selectedDate = value;
    notifyListeners();
  }

  void setStartTime(TimeOfDay value) {
    _startTime = value;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    if (endMinutes <= startMinutes) {
      _endTime = _addDurationToTime(_startTime, const Duration(hours: 1));
    }
    notifyListeners();
  }

  void setEndTime(TimeOfDay value) {
    _endTime = value;
    notifyListeners();
  }

  void resetDefaults() {
    _selectedDate = DateTime.now();
    _startTime = TimeOfDay.now();
    _endTime = _addDurationToTime(_startTime, const Duration(hours: 1));
    _isRepeating = false;
    _repeatType = 'daily';
    notifyListeners();
  }

  TimeOfDay _addDurationToTime(TimeOfDay base, Duration offset) {
    final totalMinutes = base.hour * 60 + base.minute + offset.inMinutes;
    final normalized = totalMinutes % (24 * 60);
    return TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
  }

  Future<bool> submitTask(
    BuildContext context, {
    required String taskName,
    required dynamic priority,
    required List<dynamic> tags,
    required int? categoryId,
  }) async {
    // Basic validation
    if (taskName.trim().isEmpty) {
      _showSnackBar(context, "Task name is required.");
      return false;
    }

    if (categoryId == null) {
      _showSnackBar(context, "Please select a category.");
      return false;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Map Priority String to ID
      int priorityId = 3;
      final String priorityStr = priority.toString().toLowerCase();
      if (priorityStr.contains('urgent')) {
        priorityId = 1;
      } else if (priorityStr.contains('high'))
        priorityId = 2;
      else if (priorityStr.contains('medium'))
        priorityId = 3;
      else if (priorityStr.contains('low')) priorityId = 4;

      // 2. Format Start and Due timestamps
      final startTimeDb = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      ).toUtc().toIso8601String();

      final dueTimeDb = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      ).toUtc().toIso8601String();

      final DateTime baseStart = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final DateTime baseDue = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      int? createdTemplateID;
      if (_isRepeating) {
        final templateResponse = await _supabase.from('task_template').insert({
          'title': taskName.trim(),
          'repeat_type': _repeatType,
          'category_id': categoryId,
          'priority': priorityId,
          'profile_id': user.id,
          'start_time': startTimeDb,
          'is_active': true,
        }).select('id').single();

        createdTemplateID = templateResponse['id'];
      }

      // --- CRITICAL FIX: Await the first task insertion directly ---
      final firstTaskResponse = await _supabase.from('task').insert({
        'title': taskName.trim(),
        'priority': priorityId,
        'profile_id': user.id,
        'category_id': categoryId,
        'template_id': createdTemplateID,
        'start_time': startTimeDb,
        'due_time': dueTimeDb,
        'status': 0,
      }).select('id').single();

      // Insert tags for the first task
      if (tags.isNotEmpty) {
        final int firstTaskId = firstTaskResponse['id'];
        final tagLinks = tags
            .map((tag) => {
                  'task_id': firstTaskId,
                  'tag_id': tag.id,
                })
            .toList();
        await _supabase.from('task_tags').insert(tagLinks);
      }

      // --- Handle Remaining Tasks in Background ---
      if (_isRepeating) {
        int totalTasks = (_repeatType == 'daily') ? 30 : 4;
        _createRemainingTasksInBackground(
          totalTasks: totalTasks,
          repeatType: _repeatType,
          baseStart: baseStart,
          baseDue: baseDue,
          taskName: taskName,
          priorityId: priorityId,
          user: user,
          categoryId: categoryId,
          createdTemplateID: createdTemplateID,
          tags: tags,
        );
      }
    } catch (e) {
      debugPrint("Execution Error: $e");
      if (context.mounted) {
        _showSnackBar(context, "Failed to create task: $e");
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return true;
  }

  Future<void> _createRemainingTasksInBackground({
    required int totalTasks,
    required String repeatType,
    required DateTime baseStart,
    required DateTime baseDue,
    required String taskName,
    required int priorityId,
    required User user,
    required int? categoryId,
    required int? createdTemplateID,
    required List<dynamic> tags,
  }) async {
    try {
      // Start from i = 1 because i = 0 was handled in submitTask
      for (int i = 1; i < totalTasks; i++) {
        Duration offset = (repeatType == 'daily') ? Duration(days: i) : Duration(days: i * 7);

        final String currentStart = baseStart.add(offset).toUtc().toIso8601String();
        final String currentDue = baseDue.add(offset).toUtc().toIso8601String();

        final taskResponse = await _supabase.from('task').insert({
          'title': taskName.trim(),
          'priority': priorityId,
          'profile_id': user.id,
          'category_id': categoryId,
          'template_id': createdTemplateID,
          'start_time': currentStart,
          'due_time': currentDue,
          'status': 0,
        }).select('id').single();

        if (tags.isNotEmpty) {
          final int newTaskId = taskResponse['id'];
          final tagLinks = tags
              .map((tag) => {
                    'task_id': newTaskId,
                    'tag_id': tag.id,
                  })
              .toList();
          await _supabase.from('task_tags').insert(tagLinks);
        }
      }
      debugPrint("Background remaining tasks creation completed.");
    } catch (e) {
      debugPrint("Background Task Creation Error: $e");
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

// ============================================================================
// 2. USER INTERFACE (UI)
// ============================================================================
class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Team Meeting');
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CreateTaskProvider>().resetDefaults();
      context.read<CategoryViewModel>().loadCategories();
      context.read<TagViewModel>().loadTags();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryViewModel = context.watch<CategoryViewModel>();
    final categories = categoryViewModel.categories;

    // Set default category if none selected
    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header Section ---
            _buildHeader(context, theme),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Create New Task', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 25),
                    
                    // Task Name Input
                    CustomInputField(label: 'Task Name', hint: 'Enter task name', controller: _nameController),
                    const SizedBox(height: 20),
                    
                    // Category Selection
                    Text('Select Category', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 10),
                    _buildCategorySection(categoryViewModel, categories, theme),
                    const SizedBox(height: 20),

                    // Priority and Tag Selectors (Existing Widgets)
                    const PrioritySelector(),
                    const SizedBox(height: 20),
                    const TagSelector(),
                    const SizedBox(height: 20),

                    // Date Picker Widget
                    _buildDatePicker(context, theme),
                    const SizedBox(height: 25),

                    // Time Pickers (Start & End Time)
                    _buildTimePickers(context, theme),
                    const SizedBox(height: 40),

                    _buildRepeatingSection(context, theme), 

                    const SizedBox(height: 40),

                    // Submit Button
                    _buildSubmitButton(context, theme),
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

  // --- Sub-Widgets for Cleaner Code ---

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          Icon(Icons.menu_rounded, color: theme.colorScheme.onSurface),
          Icon(Icons.assignment_outlined, color: theme.colorScheme.onSurface),
        ],
      ),
    );
  }

  Widget _buildCategorySection(CategoryViewModel vm, List<CategoryModel> categories, ThemeData theme) {
    if (categories.isEmpty) {
      return Text(vm.isLoading ? 'Loading...' : 'No categories', style: theme.textTheme.bodyMedium);
    }
    return CategoryChoiceChips(
      categories: categories,
      selectedCategoryId: _selectedCategoryId,
      onSelected: (cat) => setState(() => _selectedCategoryId = cat.id),
    );
  }

  Widget _buildDatePicker(BuildContext context, ThemeData theme) {
    return Consumer<CreateTaskProvider>(
      builder: (context, provider, _) {
        final dateStr = DateFormat('EEEE, d MMMM').format(provider.selectedDate);
        return InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: provider.selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
            );
            if (picked != null) provider.setDate(picked);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date', style: theme.textTheme.labelLarge),
                  Text(dateStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Container(width: 150, height: 1, color: theme.colorScheme.outline),
                ],
              ),
              _buildIconBox(Icons.date_range_rounded, theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimePickers(BuildContext context, ThemeData theme) {
    return Consumer<CreateTaskProvider>(
      builder: (context, provider, _) {
        return Row(
          children: [
            _buildTimeItem('Start Time', provider.startTime, theme, (t) => provider.setStartTime(t!)),
            const SizedBox(width: 20),
            _buildTimeItem('End Time', provider.endTime, theme, (t) => provider.setEndTime(t!)),
          ],
        );
      },
    );
  }

  Widget _buildTimeItem(String label, TimeOfDay time, ThemeData theme, Function(TimeOfDay?) onPick) {
    return Expanded(
      child: InkWell(
        onTap: () async {
          final picked = await showTimePicker(context: context, initialTime: time);
          onPick(picked);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.labelLarge),
                  Text(time.format(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Container(height: 1, color: theme.colorScheme.outline),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildIconBox(Icons.access_time_rounded, theme, small: true),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBox(IconData icon, ThemeData theme, {bool small = false}) {
    return Container(
      padding: EdgeInsets.all(small ? 10 : 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(small ? 12 : 15),
      ),
      child: Icon(icon, color: theme.colorScheme.onPrimary, size: small ? 20 : 24),
    );
  }

  Widget _buildRepeatingSection(BuildContext context, ThemeData theme) {
    return Consumer<CreateTaskProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // 1. DÒNG NÚT GẠT (SWITCH)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lặp lại công việc này?', style: theme.textTheme.titleMedium),
                Switch(
                  value: provider.isRepeating,
                  onChanged: (val) => provider.setRepeating(val), // Cập nhật state
                ),
              ],
            ),
            
            // 2. HIỆN TÙY CHỌN (Chỉ hiện khi Switch đang bật)
            if (provider.isRepeating)
              Row(
                children: [
                  _buildOptionBtn(
                    label: 'Hàng ngày (30 ngày)',
                    isSelected: provider.repeatType == 'daily',
                    onTap: () => provider.setRepeatType('daily'),
                    theme: theme,
                  ),
                  const SizedBox(width: 10),
                  _buildOptionBtn(
                    label: 'Hàng tuần (4 tuần)',
                    isSelected: provider.repeatType == 'weekly',
                    onTap: () => provider.setRepeatType('weekly'),
                    theme: theme,
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildOptionBtn({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final background = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = isSelected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: foreground)),
          ),
        ),
      ),
    );
  }
  

  Widget _buildSubmitButton(BuildContext context, ThemeData theme) {
    final provider = context.watch<CreateTaskProvider>();
    return Center(
      child: ElevatedButton(
        onPressed: provider.isLoading
            ? null
            : () async {
                final taskVM = context.read<TaskViewModel>();
                final tagVM = context.read<TagViewModel>();
                final taskName = _nameController.text;
                final selectedPriority = taskVM.selectedPriority;
                final selectedTags = List.from(tagVM.selectedTags);

                final success = await provider.submitTask(
                  context,
                  taskName: taskName,
                  priority: selectedPriority,
                  tags: selectedTags,
                  categoryId: _selectedCategoryId,
                );

                if (!success || !context.mounted) return;

                taskVM.reset();
                tagVM.resetSelection();
                Navigator.pop(context, provider.selectedDate);
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
        ),
        child: provider.isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Create Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_management_app/features/category/view/widgets/category_choice_chips.dart';
import 'package:task_management_app/features/category/viewmodel/category_viewmodel.dart';
import 'package:task_management_app/features/tag/view/widgets/tag_selector.dart';
import 'package:task_management_app/features/tag/viewmodel/tag_viewmodel.dart';

import '../../../../core/widgets/custom_input_field.dart';
import '../../model/task_model.dart';
import '../../viewmodel/task_viewmodel.dart';
import '../widgets/task_widgets.dart';
import '../widgets/priority_selector.dart';

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
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
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
    final categoryViewModel = context.watch<CategoryViewModel>();
    final tagViewModel = context.watch<TagViewModel>();
    String formattedDate = DateFormat('EEEE, d MMMM').format(_selectedDate);
    final categories = categoryViewModel.categories;

    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ───────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
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

                    // ─── PRIORITY SELECTOR (MỚI) ──────────────
                    const PrioritySelector(),
                    const SizedBox(height: 20),

                    // ─── TAG SELECTOR (MỚI) ───────────────────
                    const TagSelector(),
                    const SizedBox(height: 20),

                    // Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 5),
                            InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() => _selectedDate = picked);
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    width: 150,
                                    height: 1,
                                    color: Theme.of(context).colorScheme.outline,
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.date_range_rounded, color: Colors.white),
                        )
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Time
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start time',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 5),
                              TimePickerWidget(
                                time: _startTime,
                                onChanged: (t) =>
                                    setState(() => _startTime = t),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'End time',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 5),
                              TimePickerWidget(
                                time: _endTime,
                                onChanged: (t) => setState(() => _endTime = t),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                        onPressed: () {
                          final viewModel = context.read<TaskViewModel>();
                          if (categories.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please create a category first.'),
                              ),
                            );
                            return;
                          }

                          final selectedCategory = categories.firstWhere(
                            (category) => category.id == _selectedCategoryId,
                            orElse: () => categories.first,
                          );

                          final newTask = TaskModel(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            title: _nameController.text,
                            description: _descController.text,
                            category: selectedCategory,
                            startTime: _startTime,
                            endTime: _endTime,
                            date: _selectedDate,
                            priority: viewModel.selectedPriority,
                            tags: List.from(tagViewModel.selectedTags),
                          );
                          viewModel.addTask(newTask);
                          viewModel.reset();
                          context.read<TagViewModel>().resetSelection();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 100,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Create Task',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
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

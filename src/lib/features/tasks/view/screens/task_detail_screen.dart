import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_management_app/core/utils/adaptive_color_extension.dart';
import 'package:task_management_app/features/category/model/category_model.dart';
import 'package:task_management_app/features/category/view/widgets/category_choice_chips.dart';
import 'package:task_management_app/features/category/viewmodel/category_viewmodel.dart';
import 'package:task_management_app/features/tag/model/tag_model.dart';
import 'package:task_management_app/features/tag/viewmodel/tag_viewmodel.dart';

import '../../../../core/widgets/custom_input_field.dart';
import '../../model/task_model.dart';
import '../../viewmodel/task_viewmodel.dart';
import '../widgets/task_widgets.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late CategoryModel _currentCategory;
  late List<TagModel> _currentTags;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
    _startTime = widget.task.startTime;
    _endTime = widget.task.endTime;
    _currentCategory = widget.task.category;
    _currentTags = List.from(widget.task.tags);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoryViewModel>().loadCategories();
      context.read<TagViewModel>().loadTags();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _toggleTag(TagModel tag) {
    setState(() {
      if (_currentTags.any((t) => t.id == tag.id)) {
        _currentTags.removeWhere((t) => t.id == tag.id);
      } else {
        _currentTags.add(tag);
      }
    });
  }

  bool _isTagSelected(TagModel tag) => _currentTags.any((t) => t.id == tag.id);

  void _saveChanges() {
    widget.task.title = _titleController.text;
    widget.task.description = _descController.text;
    widget.task.startTime = _startTime;
    widget.task.endTime = _endTime;
    widget.task.category = _currentCategory;

    // Lưu tags mới vào task qua ViewModel
    context.read<TaskViewModel>().updateTaskTags(widget.task.id, _currentTags);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Task updated successfully!'),
        backgroundColor: Theme.of(context).colorScheme.tertiary,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categoryViewModel = context.watch<CategoryViewModel>();
    final tagViewModel = context.watch<TagViewModel>();
    String formattedDate = DateFormat('EEEE, d MMMM').format(widget.task.date);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = categoryViewModel.categories;
    final tags = tagViewModel.tags;

    if (categories.isNotEmpty && !categories.any((c) => c.id == _currentCategory.id)) {
      _currentCategory = categories.first;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Task Details',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Hero(
          tag: 'task_card_${widget.task.id}',
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(30),
                border: isDark
                    ? Border.all(color: Theme.of(context).colorScheme.outline)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task Name
                    CustomInputField(
                      label: 'Task Name',
                      hint: '',
                      controller: _titleController,
                    ),
                    const SizedBox(height: 20),

                    // Category
                    Text(
                      'Category Tag',
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
                              selectedCategoryId: _currentCategory.id,
                              onSelected: (category) {
                                setState(() => _currentCategory = category);
                              },
                            ),
                    ),
                    const SizedBox(height: 25),

                    // Date
                    Text('Date', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 5),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // ─── Tags ─────────────────────────────────
                    Text(
                      'Tags',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((tag) {
                        final adaptiveTagColor = tag.color.toAdaptiveColor(context);
                        final isSelected = _isTagSelected(tag);
                        return GestureDetector(
                          onTap: () => _toggleTag(tag),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? adaptiveTagColor
                                  : adaptiveTagColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  tag.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : adaptiveTagColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 25),

                    // Time Pickers
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
                      hint: '',
                      controller: _descController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 40),

                    // Save Button
                    Center(
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

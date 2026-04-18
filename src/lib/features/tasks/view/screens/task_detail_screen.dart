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
  // Hàm hiển thị Popup để gõ Note mới (để bên trong class TaskDetailScreen)
  void _showAddNoteDialog(BuildContext context, String taskId) {
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm Note'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Nhập nội dung ghi chú...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (noteController.text.isNotEmpty) {
                // Gọi ViewModel để lưu Note
                bool success = await context.read<TaskViewModel>().createNote(taskId, noteController.text);
                
                if (success && context.mounted) {
                  Navigator.pop(context);
                  // Load lại trang hoặc gọi setState để thấy note mới (tuỳ cách ông build màn hình)
                  setState(() {}); 
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã thêm Note!')),
                  );
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị Danh Sách Note (Ông nhét cái này vào đâu đó trong body của TaskDetailScreen)
  Widget _buildNotesSection(BuildContext context, String taskId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Notes', style: Theme.of(context).textTheme.titleLarge),
            // Nút Dấu Cộng thêm Note
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.blue, size: 30),
              onPressed: () => _showAddNoteDialog(context, taskId),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        // Dùng FutureBuilder để gọi API lấy note về
        FutureBuilder<List<NoteModel>>(
          future: context.read<TaskViewModel>().getNotesForTask(taskId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('Chưa có ghi chú nào.', style: TextStyle(color: Colors.grey));
            }

            final notes = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // Để ListView không cuộn lồng nhau
              itemCount: notes.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.sticky_note_2, color: Colors.amber),
                    title: Text(notes[index].content),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
  void _saveChanges() async {
    final Map<String, dynamic> updates = {
      'title': _titleController.text.trim(),
      'category_id': _currentCategory.id, 
    };

    try {
      await context.read<TaskViewModel>().updateTask(widget.task.id, updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thành công!')),
        );
        Navigator.pop(context); // Xong thì té về màn Home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi rồi: $e')),
        );
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: () {
              // Hiện Dialog xác nhận xóa cho an toàn
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Xóa Task?'),
                  content: const Text('Bạn có chắc muốn xóa công việc này không?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Gọi hàm xóa từ Provider/ViewModel
                        context.read<TaskViewModel>().deleteTask(widget.task.id);
                        Navigator.pop(ctx); // Tắt Dialog
                        Navigator.pop(context); // Trở về màn Home
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã xóa task thành công!'), backgroundColor: Colors.redAccent),
                        );
                      },
                      child: const Text('Xóa', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
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
                    _buildNotesSection(context, widget.task.id.toString()),

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

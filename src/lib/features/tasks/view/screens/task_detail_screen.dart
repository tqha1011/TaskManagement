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
  late TimeOfDay _startTime;
  late TimeOfDay _endTime; // Theo DB của ông thì nó tương ứng với due_time
  late CategoryModel _currentCategory;
  late List<TagModel> _currentTags;
  final TextEditingController _subtaskController = TextEditingController();
  late Future<List<dynamic>> _subtasksFuture;
  
  // Thêm biến này để fix lỗi hiệu năng gọi API liên tục của FutureBuilder
  late Future<List<dynamic>> _notesFuture; // Sửa lại List<NoteModel> nếu ông có Model riêng

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _startTime = widget.task.startTime;
    _endTime = widget.task.endTime;
    _currentCategory = widget.task.category;
    _currentTags = List.from(widget.task.tags);
    _subtasksFuture = context.read<TaskViewModel>().getSubtasksForTask(widget.task.id.toString());

    // Gọi API lấy Note lần đầu tiên
    _notesFuture = context.read<TaskViewModel>().getNotesForTask(widget.task.id.toString());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoryViewModel>().loadCategories();
      context.read<TagViewModel>().loadTags();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtaskController.dispose();
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

  // Hàm hiển thị Popup để gõ Note mới
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
                  
                  // Gán lại Future để giao diện tự cập nhật danh sách note mới nhất
                  setState(() {
                    _notesFuture = context.read<TaskViewModel>().getNotesForTask(taskId);
                  }); 
                  
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

  // Widget hiển thị Danh Sách Note
  Widget _buildNotesSection(BuildContext context, String taskId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Notes', style: Theme.of(context).textTheme.titleLarge),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.blue, size: 30),
              onPressed: () => _showAddNoteDialog(context, taskId),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        // Truyền _notesFuture vào đây thay vì gọi thẳng API
        FutureBuilder<List<dynamic>>( // Ép kiểu lại thành List<NoteModel> theo ý ông nhé
          future: _notesFuture,
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
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.sticky_note_2, color: Colors.amber),
                    title: Text(notes[index].content), // Đảm bảo model note có field content
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
  Widget _buildSubtasksSection(BuildContext context, String taskId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subtasks', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        
        // Ô nhập thêm Subtask nhanh
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _subtaskController,
                decoration: InputDecoration(
                  hintText: 'Thêm subtask mới...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onSubmitted: (value) => _handleAddSubtask(taskId),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.blue, size: 30),
              onPressed: () => _handleAddSubtask(taskId),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // Danh sách Subtask từ DB
        FutureBuilder<List<dynamic>>(
          future: _subtasksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('Chưa có subtask nào.', style: TextStyle(color: Colors.grey));
            }

            final subtasks = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subtasks.length,
              itemBuilder: (context, index) {
                final subtask = subtasks[index];
                final isDone = subtask['status'] == 1; // 1 là xong, 0 là chưa

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isDone ? Colors.blue.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDone ? Colors.blue : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: ListTile(
                    leading: GestureDetector(
                      onTap: () async {
                        // Đảo trạng thái 0 <-> 1
                        int newStatus = isDone ? 0 : 1;
                        await context.read<TaskViewModel>().updateSubtaskStatus(subtask['id'].toString(), newStatus);
                        // Cập nhật lại UI + fetch lại task ngoài Home để cập nhật con số 4/7
                        setState(() {
                          _subtasksFuture = context.read<TaskViewModel>().getSubtasksForTask(taskId);
                        });
                        context.read<TaskViewModel>().fetchTasks(); // Load lại data cho màn Home
                      },
                      child: Icon(
                        isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isDone ? Colors.blue : Colors.grey,
                        size: 28,
                      ),
                    ),
                    title: Text(
                      subtask['content'],
                      style: TextStyle(
                        color: isDone ? Colors.blue : Theme.of(context).colorScheme.onSurface,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                      onPressed: () async {
                        await context.read<TaskViewModel>().deleteSubtask(subtask['id'].toString());
                        setState(() {
                          _subtasksFuture = context.read<TaskViewModel>().getSubtasksForTask(taskId);
                        });
                        context.read<TaskViewModel>().fetchTasks();
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // Hàm xử lý việc nhấn nút Add Subtask
  Future<void> _handleAddSubtask(String taskId) async {
    final text = _subtaskController.text.trim();
    if (text.isNotEmpty) {
      await context.read<TaskViewModel>().addSubtask(taskId, text);
      _subtaskController.clear();
      setState(() {
        _subtasksFuture = context.read<TaskViewModel>().getSubtasksForTask(taskId);
      });
      context.read<TaskViewModel>().fetchTasks(); // Báo Home cập nhật số lượng
    }
  }

  void _saveChanges() async {
    final taskVM = context.read<TaskViewModel>();
    
    // Chuẩn bị dữ liệu cập nhật
    final Map<String, dynamic> updates = {
      'title': _titleController.text.trim(),
      'category_id': _currentCategory.id,
      // Ở đây ông có thể thêm logic format TimeOfDay sang ISO8601 nếu cần update giờ
    };

    // KIỂM TRA: Nếu task có template_id => Đây là task lặp
    if (widget.task.templateId != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cập nhật task lặp'),
          content: const Text('Bạn muốn áp dụng thay đổi cho chỉ task này hay toàn bộ chuỗi lặp?'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                // Chỉ update task hiện tại (dùng id của task)
                await taskVM.updateTask(widget.task.id.toString(), updates);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Chỉ task này'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                // Update toàn bộ chuỗi (dùng template_id)
                await taskVM.updateTaskSeries(widget.task.templateId!, updates);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Toàn bộ chuỗi'),
            ),
          ],
        ),
      );
    } else {
      // Nếu là task đơn bình thường => Update thẳng
      await taskVM.updateTask(widget.task.id.toString(), updates);
      if (mounted) Navigator.pop(context);
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
          // TRONG APPBAR ACTIONS
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: () {
              final taskVM = context.read<TaskViewModel>();
              
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Xóa Task?'),
                  content: Text(widget.task.templateId != null 
                      ? 'Task này thuộc một chuỗi lặp. Bạn muốn xóa thế nào?' 
                      : 'Bạn có chắc chắn muốn xóa task này?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                    
                    TextButton(
                      onPressed: () async {
                        await taskVM.deleteTask(widget.task.id.toString());
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Xóa task này', style: TextStyle(color: Colors.orange)),
                    ),

                    if (widget.task.templateId != null)
                      TextButton(
                        onPressed: () async {
                          await taskVM.deleteTaskSeries(widget.task.templateId!);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Xóa toàn bộ chuỗi', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
                      'Category',
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

                    // Tags
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
                                onChanged: (t) => setState(() => _startTime = t),
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
                                'Due time', // Đổi text thành Due time cho hợp DB
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
                    const SizedBox(height: 40),
                    
                    // Notes Section (Đã gỡ Description)
                    _buildSubtasksSection(context, widget.task.id.toString()),
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
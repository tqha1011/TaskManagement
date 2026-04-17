import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
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
  late String _currentCategory;
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
  void _saveChanges() async{
    // 1. Cập nhật dữ liệu tạm trên giao diện hiện tại
    widget.task.title = _titleController.text;
    widget.task.description = _descController.text;
    widget.task.startTime = _startTime;
    widget.task.endTime = _endTime;
    widget.task.category = _currentCategory;

    // 2. Gói hàng (Map) để gửi lên Supabase
    // Lưu ý: Key phải khớp với tên cột trong Database (ví dụ: 'title', 'start_time')
    final Map<String, dynamic> updates = {
      'title': _titleController.text,
      'description': _descController.text,
      'category': _currentCategory,
      // Ép giờ (TimeOfDay) sang chuỗi để Database hiểu được (Ví dụ: "14:30")
      'start_time': '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
      'end_time': '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
    };

    await context.read<TaskViewModel>().updateTask(widget.task.id, updates);
    await context.read<TaskViewModel>().updateTaskTags(widget.task.id, _currentTags);
    if (!mounted) return;
    

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
    final viewModel = context.watch<TaskViewModel>();
    String formattedDate = DateFormat('EEEE, d MMMM').format(widget.task.date);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Mock categories (Fetch from database later)
    List<String> categories = ['Development', 'Research', 'Design', 'Backend'];

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
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          bool isSelected =
                              categories[index] == _currentCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              label: Text(categories[index]),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(
                                    () => _currentCategory = categories[index],
                                  );
                                }
                              },
                              backgroundColor: isDark
                                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                                  : const Color(0xFFF1F7FD),
                              selectedColor: Theme.of(context).colorScheme.primary,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.primary,
                                fontSize: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isDark
                                        ? Theme.of(context).colorScheme.outline
                                        : const Color(0xFFF1F7FD),
                                    width: 1,
                                  )),
                              showCheckmark: false,
                            ),
                          );
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

                    // ─── Time Tags ────────────────────────────
                    Text(
                      'Thời gian',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: viewModel.timeTags.map((tag) {
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
                                  ? tag.color
                                  : tag.color.withValues(alpha: 0.1),
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
                                        : tag.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // ─── Status Tags ──────────────────────────
                    Text(
                      'Trạng thái',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: viewModel.statusTags.map((tag) {
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
                                  ? tag.color
                                  : tag.color.withValues(alpha: 0.1),
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
                                        : tag.color,
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

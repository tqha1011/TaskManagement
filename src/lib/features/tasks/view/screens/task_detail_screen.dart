import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/custom_input_field.dart';
import '../../model/task_model.dart';
import '../widgets/task_widgets.dart'; // Contains TimePickerWidget

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

  @override
  void initState() {
    super.initState();
    // Initialize state variables with services from the passed task object
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
    _startTime = widget.task.startTime;
    _endTime = widget.task.endTime;
    _currentCategory = widget.task.category;
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    // Update the local model
    // (Note: Later, this will call TaskViewModel -> TaskService -> your ASP.NET Core API to update the database)
    widget.task.title = _titleController.text;
    widget.task.description = _descController.text;
    widget.task.startTime = _startTime;
    widget.task.endTime = _endTime;
    widget.task.category = _currentCategory;

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task updated successfully!'), backgroundColor: Colors.green),
    );

    // Return to the previous screen
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Format date for display
    String formattedDate = DateFormat('EEEE, d MMMM').format(widget.task.date);

    // Mock categories (Fetch from database later)
    List<String> categories = ['Development', 'Research', 'Design', 'Backend'];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Task Details', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Hero(
          tag: 'task_card_${widget.task.id}', // Must match the Hero tag in the Home/Statistics screen
          child: Material( // Required inside Hero to prevent yellow underline text rendering issues
            type: MaterialType.transparency,
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Input for Task Name
                    CustomInputField(label: 'Task Name', hint: '', controller: _titleController),
                    const SizedBox(height: 20),

                    Text('Category Tag', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 10),

                    // Horizontal list of Category chips
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          bool isSelected = categories[index] == _currentCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              label: Text(categories[index]),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) setState(() => _currentCategory = categories[index]);
                              },
                              backgroundColor: const Color(0xFFF1F7FD),
                              selectedColor: Theme.of(context).colorScheme.primary,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.primary,
                                fontSize: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(color: Color(0xFFF1F7FD), width: 1)),
                              showCheckmark: false,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Display Task Date
                    Text('Date', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 5),
                    Text(formattedDate, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 25),

                    // Time Pickers for Start and End time
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Start time', style: Theme.of(context).textTheme.labelLarge),
                              const SizedBox(height: 5),
                              TimePickerWidget(time: _startTime, onChanged: (newTime) => setState(() => _startTime = newTime)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('End time', style: Theme.of(context).textTheme.labelLarge),
                              const SizedBox(height: 5),
                              TimePickerWidget(time: _endTime, onChanged: (newTime) => setState(() => _endTime = newTime)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Input for Description
                    CustomInputField(label: 'Description', hint: '', controller: _descController, maxLines: 3),
                    const SizedBox(height: 40),

                    // Save Button
                    Center(
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Save Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
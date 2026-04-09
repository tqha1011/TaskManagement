import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/custom_input_field.dart';
import '../widgets/task_widgets.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Team Meeting');
  final TextEditingController _descController = TextEditingController(text: 'Discuss all questions about new projects');
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  int _selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEEE, d MMMM').format(_selectedDate);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10, offset: const Offset(0, 5))
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Create New Task', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 25),
                    CustomInputField(label: 'Task Name', hint: 'Enter task name', controller: _nameController),
                    const SizedBox(height: 20),
                    Text('Select Category', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          List<String> categories = ['Development', 'Research', 'Design', 'Backend'];
                          bool isSelected = index == _selectedCategoryIndex;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              label: Text(categories[index]),
                              selected: isSelected,
                              onSelected: (selected) => setState(() => _selectedCategoryIndex = selected ? index : 0),
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
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date', style: Theme.of(context).textTheme.labelLarge),
                            const SizedBox(height: 5),
                            InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                    context: context, initialDate: _selectedDate,
                                    firstDate: DateTime(2000), lastDate: DateTime(2100));
                                if (picked != null) setState(() => _selectedDate = picked);
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
                            )
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
                    CustomInputField(label: 'Description', hint: 'Enter task description', controller: _descController, maxLines: 2),
                    const SizedBox(height: 40),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text('Create Task', style: TextStyle(fontSize: 18)),
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
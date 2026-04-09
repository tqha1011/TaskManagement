import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 
import '../../../../core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateTaskProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // Form state variables
  String _taskName = "";
  String _selectedCategory = "Development";
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 11, minute: 0);
  String _description = "";
  bool _isLoading = false;

  // Getters for UI consumption
  String get taskName => _taskName;
  String get selectedCategory => _selectedCategory;
  DateTime get selectedDate => _selectedDate;
  TimeOfDay get startTime => _startTime;
  TimeOfDay get endTime => _endTime;
  String get description => _description;
  bool get isLoading => _isLoading;

  // State update methods
  void setTaskName(String value) { _taskName = value; notifyListeners(); }
  void setCategory(String value) { _selectedCategory = value; notifyListeners(); }
  void setDate(DateTime value) { _selectedDate = value; notifyListeners(); }
  void setStartTime(TimeOfDay value) { _startTime = value; notifyListeners(); }
  void setEndTime(TimeOfDay value) { _endTime = value; notifyListeners(); }
  void setDescription(String value) { _description = value; notifyListeners(); }

  /// Validates input and persists the new task to Supabase
  Future<void> onCreateTaskPressed(BuildContext context) async {
    
    if (_taskName.trim().isEmpty) {
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
      // Map category labels to specific database IDs based on the provided schema
      final categoryMapping = {
        "Development": 1,
        "Research": 2,
        "Design": 3,
        "Backend": 4,
      };
      int categoryId = categoryMapping[_selectedCategory] ?? 1;

      // Construct a unified timestamp from selected date and start time
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      // Execute insert operation. 
      // Note: 'description' is omitted as it does not exist in the current 'task' table schema.
      await _supabase.from('task').insert({
        'title': _taskName.trim(),
        'status': 0, 
        'priority': 1,
        'profile_id': user.id, 
        'category_id': categoryId,
        'create_at': scheduledDateTime.toIso8601String(),
      });

      if (context.mounted) {
        _showSnackBar(context, "Task created successfully.");
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Data Persistence Error: $e");
      if (context.mounted) {
        _showSnackBar(context, "Database synchronization failed.");
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class CreateTaskScreen extends StatelessWidget {
  const CreateTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Task Name"),
                        _buildInputField(
                          hint: "Enter task name...",
                          onChanged: (v) => context.read<CreateTaskProvider>().setTaskName(v),
                        ),
                        const SizedBox(height: 25),
                        _buildSectionTitle("Select Category"),
                        _buildCategorySelector(),
                        const SizedBox(height: 25),
                        _buildDateSelector(context),
                        const SizedBox(height: 25),
                        _buildTimeSelectors(context),
                        const SizedBox(height: 25),
                        _buildSectionTitle("Description"),
                        _buildInputField(
                          hint: "Add supplementary notes...",
                          maxLines: 4,
                          onChanged: (v) => context.read<CreateTaskProvider>().setDescription(v),
                        ),
                        const SizedBox(height: 40),
                        _buildCreateButton(context),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "New Task",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title, 
        style: const TextStyle(fontSize: 16, color: AppColors.primaryBlue, fontWeight: FontWeight.bold)
      ),
    );
  }

  Widget _buildInputField({required String hint, int maxLines = 1, Function(String)? onChanged}) {
    return TextField(
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 18, color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textDark.withOpacity(0.4), fontSize: 18),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryBlue)),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Consumer<CreateTaskProvider>(
      builder: (context, provider, child) {
        final categories = ["Development", "Research", "Design", "Backend"];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final isSelected = cat == provider.selectedCategory;
              return GestureDetector(
                onTap: () => provider.setCategory(cat),
                child: Container(
                  margin: const EdgeInsets.only(right: 15),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryBlue : AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textLightBlue,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return Consumer<CreateTaskProvider>(
      builder: (context, provider, child) {
        final formattedDate = DateFormat('EEEE, d MMMM').format(provider.selectedDate);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Date"),
            Row(
              children: [
                Expanded(
                  child: Text(formattedDate, style: const TextStyle(color: Colors.black, fontSize: 18)),
                ),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: provider.selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) provider.setDate(picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.calendar_month, color: Colors.white, size: 20),
                  ),
                )
              ],
            ),
            const Divider(color: Colors.black12),
          ],
        );
      },
    );
  }

  Widget _buildTimeSelectors(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _timeField(context, "Start Time", true)),
        const SizedBox(width: 30),
        Expanded(child: _timeField(context, "End Time", false)),
      ],
    );
  }

  Widget _timeField(BuildContext context, String title, bool isStart) {
    return Consumer<CreateTaskProvider>(
      builder: (context, provider, child) {
        final time = isStart ? provider.startTime : provider.endTime;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(title),
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: time);
                if (picked != null) {
                  isStart ? provider.setStartTime(picked) : provider.setEndTime(picked);
                }
              },
              child: Row(
                children: [
                  Text(time.format(context), style: const TextStyle(color: Colors.black, fontSize: 18)),
                  const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryBlue, size: 18),
                ],
              ),
            ),
            const Divider(color: Colors.black12),
          ],
        );
      },
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    final provider = context.watch<CreateTaskProvider>();
    return Center(
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: provider.isLoading ? null : () => provider.onCreateTaskPressed(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: provider.isLoading 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("Confirm Task Creation", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
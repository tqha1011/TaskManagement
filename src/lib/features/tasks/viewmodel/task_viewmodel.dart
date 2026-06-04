import 'package:flutter/material.dart';
import 'package:task_management_app/features/tag/model/tag_model.dart';
import 'dart:convert'; 
import 'package:shared_preferences/shared_preferences.dart';
import '../model/task_model.dart';
import 'package:task_management_app/features/category/model/category_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_management_app/features/tasks/service/notif_service.dart';

class TaskViewModel extends ChangeNotifier {

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
  
  // ─── Custom Tags (lưu SharedPreferences) ────────────────
  List<TagModel> _customTags = [];
  List<TagModel> get customTags => List.unmodifiable(_customTags);

  static const _customTagsKey = 'custom_tags';
  static const _maxCustomTags = 5;
  static const _maxCustomTagLength = 12;

  TaskViewModel() {
    _loadCustomTags();
  }

  Future<void> _loadCustomTags() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customTagsKey);
    if (raw != null) {
      final List decoded = jsonDecode(raw);
      _customTags = decoded.map((e) => TagModel.fromJson(e)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveCustomTags() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _customTags
          .map((t) => {'id': t.id, 'name': t.name, 'color': t.color.toARGB32()})
          .toList(),
    );
    await prefs.setString(_customTagsKey, encoded);
  }

  // Trả về lỗi nếu có, null nếu thành công
  String? addCustomTag(String name) {
    name = name.trim();
    if (name.isEmpty) return 'Tên tag không được để trống';
    if (name.length > _maxCustomTagLength) {
      return 'Tối đa $_maxCustomTagLength ký tự';
    }
    if (_customTags.length >= _maxCustomTags) {
      return 'Tối đa $_maxCustomTags tag custom';
    }
    if (_customTags.any((t) => t.name.toLowerCase() == name.toLowerCase())) {
      return 'Tag đã tồn tại';
    }
    _customTags.add(
      TagModel(
        id: DateTime.now().millisecondsSinceEpoch, 
        name: name,
        colorCode: '#FF9800', 
        profileId: '',
      ),
    );
    _saveCustomTags();
    notifyListeners();
    return null;
  }

  final List<Color> _customTagColors = const [
    Color(0xFFE91E63),
    Color(0xFF673AB7),
    Color(0xFF795548),
    Color(0xFF009688),
    Color(0xFFFF5722),
  ];

  // ─── State tạo task ─────────────────────────────────────
  Priority _selectedPriority = Priority.medium;

  Priority get selectedPriority => _selectedPriority;

  void setPriority(Priority priority) {
    _selectedPriority = priority;
    notifyListeners();
  }

  void reset() {
    _selectedPriority = Priority.medium;
    notifyListeners();
  }

  // ─── Task list + filter/sort ─────────────────────────────
  final List<TaskModel> _tasks = [];
  List<TaskModel> get tasks => _getFilteredAndSorted();

  TaskModel? getTaskById(String taskId) {
    try {
      return _tasks.firstWhere((task) => task.id == taskId);
    } catch (_) {
      return null;
    }
  }

  Priority? _filterPriority;
  String? _filterTagId;
  bool _sortByPriority = false;

  Priority? get filterPriority => _filterPriority;
  String? get filterTagId => _filterTagId;
  bool get sortByPriority => _sortByPriority;

  void setFilterPriority(Priority? priority) {
    _filterPriority = priority;
    notifyListeners();
  }

  void setFilterTag(String? tagId) {
    _filterTagId = tagId;
    notifyListeners();
  }

  void toggleSortByPriority() {
    _sortByPriority = !_sortByPriority;
    notifyListeners();
  }

  // Cập nhật tag cho task đã tạo (dùng ở Task Detail)
  Future<void> updateTaskTags(String taskId, List<TagModel> newTags) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index].tags = newTags;
      notifyListeners();
    }
  }
  void addTask(TaskModel task) {
    _tasks.add(task);
    notifyListeners();
  }

  // Cập nhật tag cho task đã tạo (dùng ở Task Detail)

  DateTime? _parseDbDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      final normalized = value.contains('T') ? value : value.replaceFirst(' ', 'T');
      return DateTime.tryParse(normalized);
    }
    return null;
  }

  DateTime _normalizeLocal(DateTime dateTime) {
    return dateTime.isUtc ? dateTime.toLocal() : dateTime;
  }

  Future<void> fetchTasks() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    try {
      final data = await supabase
          .from('task')
          .select('*, subtask(*), category(*), task_tags(tag(*))')
          .eq('profile_id', user.id)
          .order('create_at', ascending: true);

      final List<TaskModel> fetchedTasks = [];

      for (var item in data) {
        // Xử lý Priority
        Priority p = Priority.medium;
        if (item['priority'] == 1) {
          p = Priority.urgent;
        } else if (item['priority'] == 2)
          p = Priority.high;
        else if (item['priority'] == 4) p = Priority.low;

        // Xử lý Giờ giấc thực tế từ DB
        final rawStart = _parseDbDateTime(item['start_time']);
        final rawDue = _parseDbDateTime(item['due_time']);
        final rawCreated = _parseDbDateTime(item['create_at']);

        final DateTime startTimeDt = _normalizeLocal(
          rawStart ?? rawDue ?? rawCreated ?? DateTime.now(),
        );
        final DateTime dueTimeDt = _normalizeLocal(
          rawDue ?? startTimeDt.add(const Duration(hours: 1)),
        );

        final bool isCompleted = (item['status'] ?? 0) == 1;
        int total = 0;
        int completed = 0;
        if (item['subtask'] != null) {
          final List<dynamic> subtaskList = item['subtask'];
          total = subtaskList.length;
          completed = subtaskList.where((s) => s['status'] == 1).length;
        }

        // Xử lý Category thực tế
        CategoryModel cat = CategoryModel(
          id: item['category_id'] ?? 0,
          name: 'Category',
          colorCode: '#5A8DF3',
          profileId: item['profile_id'] ?? '',
        );
        if (item['category'] != null) {
          cat = CategoryModel.fromJson(item['category']);
        }

        // Xử lý Tags thực tế
        List<TagModel> tags = [];
        if (item['task_tags'] != null) {
          final List<dynamic> tagJoins = item['task_tags'];
          for (var join in tagJoins) {
            if (join['tag'] != null) {
              tags.add(TagModel.fromJson(join['tag']));
            }
          }
        }

        fetchedTasks.add(TaskModel(
          id: item['id'].toString(),
          title: item['title'] ?? 'Task mới',
          description: item['description'] ?? '',
          templateId: item['template_id'],
          category: cat,
          tags: tags,
          startTime:
              TimeOfDay(hour: startTimeDt.hour, minute: startTimeDt.minute),
          endTime: TimeOfDay(hour: dueTimeDt.hour, minute: dueTimeDt.minute),
          date: startTimeDt,
          priority: p,
          totalSubtasks: total,
          completedSubtasks: completed,
          isCompleted: isCompleted,
        ));

        final int taskIdInt = item['id'];
        final String taskTitle = item['title'] ?? 'Task mới';

        // --- ISOLATE NOTIFICATION ERRORS ---
        try {
          // 1. Hẹn giờ nhắc trước 1 ngày
          await NotifService().scheduleTaskNotification(
            taskId: taskIdInt * 2,
            taskTitle: taskTitle,
            taskStartTime: startTimeDt,
            remindBefore: const Duration(days: 1),
            notificationMessage: 'Task "$taskTitle" sẽ bắt đầu sau 1 ngày',
          );

          // 2. Hẹn giờ nhắc trước 1 tiếng
          await NotifService().scheduleTaskNotification(
            taskId: taskIdInt * 2 + 1,
            taskTitle: taskTitle,
            taskStartTime: startTimeDt,
            remindBefore: const Duration(hours: 1),
            notificationMessage: 'Task "$taskTitle" sẽ bắt đầu sau 1 tiếng',
          );
        } catch (notifError) {
          debugPrint("Lỗi đặt thông báo cho task $taskIdInt: $notifError");
          // Continue loop even if notification fails
        }
      }

      _tasks.clear();
      _tasks.addAll(fetchedTasks);
    } catch (e) {
      debugPrint("Lỗi lấy task: $e");
    } finally {
      // --- GUARANTEE UI UPDATE ---
      notifyListeners();
    }
  }

  Future<void> updateTask(dynamic taskId, Map<String, dynamic> data) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase
          .from('task')
          .update(data) 
          .eq('id', taskId);
      
      await fetchTasks(); 
      
    } catch (e) {
      debugPrint("Lỗi update task: $e");
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase.from('task').delete().eq('id', taskId);
      // Gọi fetch lại để làm mới danh sách
      fetchTasks();
    } catch (e) {
      debugPrint("Lỗi xóa: $e");
    }
  }

  List<TaskModel> _getFilteredAndSorted() {
    List<TaskModel> result = List.from(_tasks);

    // 1. Lọc theo ngày (Date)
    result = result.where((t) {
      final taskDate = DateTime(t.date.year, t.date.month, t.date.day);
      final selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      return taskDate.isAtSameMomentAs(selectedDate);
    }).toList();

    // 2. Ẩn task đã hoàn thành khỏi danh sách chính
    result = result.where((t) => !t.isCompleted).toList();

    // 2. Lọc theo Priority (Logic so sánh rất gọn vì dùng thẳng enum)
    if (_filterPriority != null) {
      result = result.where((t) => t.priority == _filterPriority).toList();
    }

    // 3. Lọc theo Tag
    if (_filterTagId != null) {
      result = result
          .where((t) => t.tags.any((tag) => tag.id.toString() == _filterTagId))
          .toList();
    }

    // 4. Sắp xếp theo priority (urgent → high → medium → low)
    if (_sortByPriority) {
      const order = [
        Priority.urgent,
        Priority.high,
        Priority.medium,
        Priority.low,
      ];
      result.sort(
        (a, b) =>
            order.indexOf(a.priority).compareTo(order.indexOf(b.priority)),
      );
    }
    
    return result;
  }

  Future<List<NoteModel>> getNotesForTask(String taskId) async {
    final supabase = Supabase.instance.client;
    try {
      final data = await supabase
          .from('note')
          .select('*')
          .eq('task_id', int.parse(taskId)) // Tìm note theo ID của task
          .order('id', ascending: false); // Sắp xếp note mới nhất lên đầu

      return (data as List).map((e) => NoteModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Lỗi lấy note: $e");
      return [];
    }
  }

  // 2. Thêm note mới vào DB
  Future<bool> createNote(String taskId, String content) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase.from('note').insert({
        'task_id': int.parse(taskId), // Nối đúng vào task hiện tại
        'content': content,
        'pinned': false, // Mặc định không ghim
      });
      return true; // Báo hiệu lưu thành công
    } catch (e) {
      debugPrint("Lỗi tạo note: $e");
      return false;
    }
  }

  // 1. Lấy danh sách Subtask của một Task
  Future<List<dynamic>> getSubtasksForTask(String taskId) async {
    final supabase = Supabase.instance.client;
    try {
      final data = await supabase
          .from('subtask')
          .select()
          .eq('task_id', int.parse(taskId)) // DB ông lưu int8 nên parse sang int cho chắc
          .order('created_at', ascending: true);
      return data;
    } catch (e) {
      debugPrint("Lỗi lấy danh sách subtask: $e");
      return [];
    }
  }

  // 2. Thêm Subtask mới
  Future<bool> addSubtask(String taskId, String content) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase.from('subtask').insert({
        'task_id': int.parse(taskId),
        'content': content,
        'status': 0, // Mặc định là 0 (chưa hoàn thành)
      });
      return true;
    } catch (e) {
      debugPrint("Lỗi thêm subtask: $e");
      return false;
    }
  }

  // 3. Cập nhật trạng thái Subtask (Check / Uncheck)
  Future<bool> updateSubtaskStatus(String subtaskId, int newStatus) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase
          .from('subtask')
          .update({'status': newStatus})
          .eq('id', int.parse(subtaskId));
      return true;
    } catch (e) {
      debugPrint("Lỗi cập nhật trạng thái subtask: $e");
      return false;
    }
  }

  // 4. Xóa Subtask
  Future<bool> deleteSubtask(String subtaskId) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase
          .from('subtask')
          .delete()
          .eq('id', int.parse(subtaskId));
      return true;
    } catch (e) {
      debugPrint("Lỗi xóa subtask: $e");
      return false;
    }
  }

  Future<void> updateTaskSeries(int templateId, Map<String, dynamic> updates) async {
  final supabase = Supabase.instance.client;
  try {
    
    final Map<String, dynamic> seriesData = {
      'title': updates['title'],
      'category_id': updates['category_id'],
      'priority': updates['priority'],
    };

    
    await supabase
        .from('task')
        .update(seriesData)
        .eq('template_id', templateId);

    
    await supabase
        .from('task_template')
        .update(seriesData)
        .eq('id', templateId);

    await fetchTasks(); // Load lại data cho toàn app
  } catch (e) {
    debugPrint("Lỗi update chuỗi task: $e");
    rethrow;
  }
}


Future<void> deleteTaskSeries(int templateId) async {
  final supabase = Supabase.instance.client;
  try {
   
    
   
    await supabase.from('task').delete().eq('template_id', templateId);
    
   
    await supabase.from('task_template').delete().eq('id', templateId);
    
    await fetchTasks();
  } catch (e) {
    debugPrint("Lỗi xóa chuỗi task: $e");
    rethrow;
  }
}

  
}

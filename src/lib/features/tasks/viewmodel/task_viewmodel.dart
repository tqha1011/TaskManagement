import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/task_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TaskViewModel extends ChangeNotifier {

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
  final List<TagModel> workTypeTags = [
    TagModel(id: 'work', name: 'Work', color: const Color(0xFF2196F3)),
    TagModel(id: 'study', name: 'Study', color: const Color(0xFF9C27B0)),
    TagModel(id: 'personal', name: 'Personal', color: const Color(0xFF4CAF50)),
    TagModel(id: 'project', name: 'Project', color: const Color(0xFFFF9800)),
  ];

  final List<TagModel> timeTags = [
    TagModel(id: 'today', name: 'Today', color: const Color(0xFF00BCD4)),
    TagModel(id: 'tomorrow', name: 'Tomorrow', color: const Color(0xFF3F51B5)),
    TagModel(
      id: 'this_week',
      name: 'This Week',
      color: const Color(0xFF009688),
    ),
    TagModel(id: 'later', name: 'Later', color: const Color(0xFF607D8B)),
  ];

  final List<TagModel> statusTags = [
    TagModel(id: 'pending', name: 'Pending', color: const Color(0xFFFF9800)),
    TagModel(
      id: 'in_progress',
      name: 'In Progress',
      color: const Color(0xFF2196F3),
    ),
    TagModel(
      id: 'completed',
      name: 'Completed',
      color: const Color(0xFF4CAF50),
    ),
    TagModel(
      id: 'cancelled',
      name: 'Cancelled',
      color: const Color(0xFF9E9E9E),
    ),
  ];

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
      _customTags = decoded
          .map(
            (e) => TagModel(
              id: e['id'],
              name: e['name'],
              color: Color(e['color']),
            ),
          )
          .toList();
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
    if (name.length > _maxCustomTagLength)
      return 'Tối đa $_maxCustomTagLength ký tự';
    if (_customTags.length >= _maxCustomTags)
      return 'Tối đa $_maxCustomTags tag custom';
    if (_customTags.any((t) => t.name.toLowerCase() == name.toLowerCase())) {
      return 'Tag đã tồn tại';
    }
    _customTags.add(
      TagModel(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        color: _customTagColors[_customTags.length % _customTagColors.length],
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
  final List<TagModel> _selectedTags = [];

  Priority get selectedPriority => _selectedPriority;
  List<TagModel> get selectedTags => List.unmodifiable(_selectedTags);

  

  void setPriority(Priority priority) {
    _selectedPriority = priority;
    notifyListeners();
  }

  void toggleTag(TagModel tag) {
    if (_selectedTags.any((t) => t.id == tag.id)) {
      _selectedTags.removeWhere((t) => t.id == tag.id);
    } else {
      _selectedTags.add(tag);
    }
    notifyListeners();
  }

  bool isTagSelected(TagModel tag) => _selectedTags.any((t) => t.id == tag.id);

  void reset() {
    _selectedPriority = Priority.medium;
    _selectedTags.clear();
    notifyListeners();
  }

  // ─── Task list + filter/sort ─────────────────────────────
  final List<TaskModel> _tasks = [];
  List<TaskModel> get tasks => _getFilteredAndSorted();

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

  Future<void> fetchTasks() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    if (user == null) return; 

    try {
      final data = await supabase
          .from('task')
          .select('*')
          .eq('profile_id', user.id) 
          .order('create_at', ascending: true);
      
      if (data != null) {
        _tasks.clear(); 
        
        for (var item in data) {
          // 1. Chuyển đổi Priority trực tiếp
          Priority p = Priority.medium;
          if (item['priority'] == 1) p = Priority.urgent;
          else if (item['priority'] == 2) p = Priority.high;
          else if (item['priority'] == 4) p = Priority.low;

          // 2. Nhét data thẳng vào TaskModel luôn, đách cần fromJson nữa
          _tasks.add(TaskModel(
            id: item['id'].toString(),
            title: item['title'] ?? 'Task mới',
            description: item['description'] ?? '',
            category: item['category'] ?? '',
            // Mấy cái giờ giấc cho mặc định hết đi, chừng nào khỏe code tiếp
            startTime: const TimeOfDay(hour: 8, minute: 0), 
            endTime: const TimeOfDay(hour: 9, minute: 0),
            date: item['create_at'] != null 
                ? DateTime.tryParse(item['create_at'].toString()) ?? DateTime.now()
                : DateTime.now(),
            priority: p,
          )); 
        }
      }
      notifyListeners();
      
    } catch (e) {
      debugPrint("Lỗi lấy task: $e");
    }
  }


  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase.from('task').update(updates).eq('id', taskId);
      // Gọi fetch lại để làm mới danh sách màn Home
      fetchTasks(); 
    } catch (e) {
      debugPrint("Lỗi update: $e");
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
    // Tìm đoạn này trong _getFilteredAndSorted()
    result = result.where((t) {
      // Đổi t.startTime thành t.date (hoặc tên biến đúng của ông)
      return t.date.day == _selectedDate.day &&
             t.date.month == _selectedDate.month &&
             t.date.year == _selectedDate.year;
    }).toList();

    // 2. Lọc theo Priority (Logic so sánh rất gọn vì dùng thẳng enum)
    if (_filterPriority != null) {
      result = result.where((t) => t.priority == _filterPriority).toList();
    }

    // 3. Lọc theo Tag
    if (_filterTagId != null) {
      result = result
          .where((t) => t.tags.any((tag) => tag.id == _filterTagId))
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
}

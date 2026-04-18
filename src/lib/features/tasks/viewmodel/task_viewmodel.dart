import 'package:flutter/material.dart';
import 'package:task_management_app/features/tag/model/tag_model.dart';
import 'dart:convert'; 
import 'package:shared_preferences/shared_preferences.dart';
import '../model/task_model.dart';
import 'package:task_management_app/features/category/model/category_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TaskViewModel extends ChangeNotifier {

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
  final List<TagModel> workTypeTags = [
    const TagModel(id: 1, name: 'Work', colorCode: '#2196F3', profileId: ''),
    const TagModel(id: 2, name: 'Study', colorCode: '#9C27B0', profileId: ''),
    const TagModel(id: 3, name: 'Personal', colorCode: '#4CAF50', profileId: ''),
    const TagModel(id: 4, name: 'Project', colorCode: '#FF9800', profileId: ''),
  ];

  final List<TagModel> timeTags = [
    const TagModel(id: 5, name: 'Today', colorCode: '#00BCD4', profileId: ''),
    const TagModel(id: 6, name: 'Tomorrow', colorCode: '#3F51B5', profileId: ''),
    const TagModel(id: 7, name: 'This Week', colorCode: '#009688', profileId: ''),
    const TagModel(id: 8, name: 'Later', colorCode: '#607D8B', profileId: ''),
  ];

  final List<TagModel> statusTags = [
    const TagModel(id: 9, name: 'Pending', colorCode: '#FF9800', profileId: ''),
    const TagModel(id: 10, name: 'In Progress', colorCode: '#2196F3', profileId: ''),
    const TagModel(id: 11, name: 'Completed', colorCode: '#4CAF50', profileId: ''),
    const TagModel(id: 12, name: 'Cancelled', colorCode: '#9E9E9E', profileId: ''),
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
    if (name.length > _maxCustomTagLength)
      return 'Tối đa $_maxCustomTagLength ký tự';
    if (_customTags.length >= _maxCustomTags)
      return 'Tối đa $_maxCustomTags tag custom';
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
            
            // CHÍNH LÀ CHỖ NÀY: Khởi tạo cục CategoryModel đàng hoàng
            category: CategoryModel(
              id: 0, // Nhét số 0 vào làm ID ảo
              name: item['category']?.toString() ?? 'General', // Lấy tên từ database, nếu rỗng thì cho chữ General
              colorCode: '#5A8DF3', // Lấy màu mặc định
              profileId: '', // Bỏ trống
            ),
            
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


  Future<void> updateTask(dynamic taskId, Map<String, dynamic> data) async {
  final _supabase = Supabase.instance.client;
  try {
    await _supabase
        .from('task')
        .update(data) // Data ở đây sẽ chứa {'title': '...', 'category_id': ...}
        .eq('id', taskId);
    
    notifyListeners(); // Để màn hình Home load lại dữ liệu mới
  } catch (e) {
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
}

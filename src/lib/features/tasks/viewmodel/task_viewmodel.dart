import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/task_model.dart';

class TaskViewModel extends ChangeNotifier {
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

  void addTask(TaskModel task) {
    _tasks.add(task);
    notifyListeners();
  }

  // Cập nhật tag cho task đã tạo (dùng ở Task Detail)
  void updateTaskTags(String taskId, List<TagModel> newTags) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index].tags = newTags;
      notifyListeners();
    }
  }

  List<TaskModel> _getFilteredAndSorted() {
    List<TaskModel> result = List.from(_tasks);
    if (_filterPriority != null) {
      result = result.where((t) => t.priority == _filterPriority).toList();
    }
    if (_filterTagId != null) {
      result = result
          .where((t) => t.tags.any((tag) => tag.id == _filterTagId))
          .toList();
    }
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
}

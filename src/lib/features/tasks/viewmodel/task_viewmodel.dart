import 'package:flutter/material.dart';
import '../model/task_model.dart';

class TaskViewModel extends ChangeNotifier {
  // ─── Danh sách tag có sẵn
  final List<TagModel> availableTags = [
    TagModel(id: 'work', name: 'Work', color: const Color(0xFF2196F3)),
    TagModel(id: 'study', name: 'Study', color: const Color(0xFF9C27B0)),
    TagModel(id: 'personal', name: 'Personal', color: const Color(0xFF4CAF50)),
    TagModel(id: 'project', name: 'Project', color: const Color(0xFFFF9800)),
  ];

  // ─── State khi đang tạo task
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

  // ─── Danh sách task + filter/sort ────────────────────────
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

  List<TaskModel> _getFilteredAndSorted() {
    List<TaskModel> result = List.from(_tasks);

    // Lọc theo priority
    if (_filterPriority != null) {
      result = result.where((t) => t.priority == _filterPriority).toList();
    }

    // Lọc theo tag
    if (_filterTagId != null) {
      result = result
          .where((t) => t.tags.any((tag) => tag.id == _filterTagId))
          .toList();
    }

    // Sắp xếp theo priority (urgent → high → medium → low)
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

import 'package:flutter/material.dart';
import 'package:task_management_app/features/tag/model/tag_model.dart';

import '../model/task_model.dart';

class TaskViewModel extends ChangeNotifier {
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
          .where((t) => t.tags.any((tag) => tag.id.toString() == _filterTagId))
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

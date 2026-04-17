import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../model/tag_model.dart';
import '../repository/tag_repository.dart';

class TagViewModel extends ChangeNotifier {
  static const int _maxCustomTagLength = 12;

  final TagRepository _repository;

  TagViewModel({TagRepository? repository})
      : _repository = repository ?? TagRepository();

  final List<TagModel> _tags = [];
  final Set<int> _selectedTagIds = <int>{};

  List<TagModel> get tags => List.unmodifiable(_tags);

  List<TagModel> get selectedTags =>
      _tags.where((tag) => _selectedTagIds.contains(tag.id)).toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadTags() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _repository.fetchTags();
      _tags
        ..clear()
        ..addAll(data);
      _selectedTagIds.removeWhere((id) => !_tags.any((tag) => tag.id == id));
    } catch (e) {
      _error = e.toString();
      _tags.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isTagSelected(TagModel tag) => _selectedTagIds.contains(tag.id);

  void toggleTag(TagModel tag) {
    if (_selectedTagIds.contains(tag.id)) {
      _selectedTagIds.remove(tag.id);
    } else {
      _selectedTagIds.add(tag.id);
    }
    notifyListeners();
  }

  void setSelectedTags(List<TagModel> tags) {
    _selectedTagIds
      ..clear()
      ..addAll(tags.map((e) => e.id));
    notifyListeners();
  }

  void resetSelection() {
    _selectedTagIds.clear();
    notifyListeners();
  }

  Future<String?> addCustomTag(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Tên tag không được để trống';
    if (trimmed.length > _maxCustomTagLength) {
      return 'Tối đa $_maxCustomTagLength ký tự';
    }
    if (_tags.any((t) => t.name.toLowerCase() == trimmed.toLowerCase())) {
      return 'Tag đã tồn tại';
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final colorCode = _generateColorCode();
      final created = await _repository.createCustomTag(trimmed, colorCode);
      _tags.add(created);
      _selectedTagIds.add(created.id);
      return null;
    } catch (e) {
      _error = e.toString();
      return 'Không thể tạo tag. Vui lòng thử lại';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _generateColorCode() {
    const palette = <String>[
      '#E91E63',
      '#673AB7',
      '#795548',
      '#009688',
      '#FF5722',
      '#4A90E2',
    ];
    return palette[_tags.length % palette.length];
  }
}


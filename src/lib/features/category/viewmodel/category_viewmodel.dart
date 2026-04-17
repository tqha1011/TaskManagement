import 'package:flutter/foundation.dart';

import '../model/category_model.dart';
import '../repository/category_repository.dart';

class CategoryViewModel extends ChangeNotifier {
  final CategoryRepository _repository;

  CategoryViewModel({CategoryRepository? repository})
      : _repository = repository ?? CategoryRepository();

  final List<CategoryModel> _categories = [];

  List<CategoryModel> get categories => List.unmodifiable(_categories);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _repository.fetchCategories();
      _categories
        ..clear()
        ..addAll(data);
    } catch (e) {
      _error = e.toString();
      _categories.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}


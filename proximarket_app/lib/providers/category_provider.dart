import 'package:flutter/material.dart';

class CategoryProvider extends ChangeNotifier {
  String? _selectedCategory;

  String? get selectedCategory => _selectedCategory;

  void selectCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void reset() {
    _selectedCategory = null;
    notifyListeners();
  }
}
import 'package:flutter/material.dart';
import '../models/photo_category_model.dart';
import '../services/categories_service.dart';

class CategoriesProvider extends ChangeNotifier {
  final _service = CategoriesService();

  List<PhotoCategoryModel> _all = [];
  List<PhotoCategoryModel> _enabled = [];
  bool _isLoading = false;
  String? _error;

  List<PhotoCategoryModel> get all => _all;
  List<PhotoCategoryModel> get enabled => _enabled;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// التصنيفات بالصيغة القديمة (توافقية مع الكود الموجود)
  List<Map<String, String>> get categoriesAsMap {
    final list = <Map<String, String>>[
      {'key': 'all', 'ar': 'الكل', 'en': 'All'},
    ];
    for (final c in _enabled) {
      list.add({
        'key': c.key,
        'ar': c.labelAr,
        'en': c.labelEn,
      });
    }
    return list;
  }

  Future<void> load({bool adminMode = false}) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (adminMode) {
        _all = await _service.getCategories();
      }
      _enabled = await _service.getCategories(onlyEnabled: true);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> create({
    required String key,
    required String labelAr,
    required String labelEn,
    String? iconName,
    int displayOrder = 99,
  }) async {
    await _service.createCategory(
      key: key,
      labelAr: labelAr,
      labelEn: labelEn,
      iconName: iconName,
      displayOrder: displayOrder,
    );
    await load(adminMode: true);
  }

  Future<void> update(String id, Map<String, dynamic> updates) async {
    await _service.updateCategory(id, updates);
    await load(adminMode: true);
  }

  Future<void> delete(String id) async {
    await _service.deleteCategory(id);
    await load(adminMode: true);
  }

  /// الحصول على تسمية تصنيف بالعربية
  String labelFor(String key) {
    if (key == 'all') return 'الكل';
    final cat = _enabled.firstWhere(
      (c) => c.key == key,
      orElse: () => PhotoCategoryModel(
        id: '',
        key: key,
        labelAr: key,
        labelEn: key,
        enabled: true,
        displayOrder: 0,
        createdAt: DateTime.now(),
      ),
    );
    return cat.labelAr;
  }
}

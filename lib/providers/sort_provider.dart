import 'package:flutter/material.dart';
import '../models/sort_option_model.dart';
import '../services/sort_service.dart';

class SortProvider extends ChangeNotifier {
  final _service = SortService();

  List<SortOptionModel> _allSorts = [];
  List<SortOptionModel> _enabledSorts = [];
  String _currentSort = 'newest';
  bool _isLoading = false;
  String? _error;

  List<SortOptionModel> get allSorts => _allSorts;
  List<SortOptionModel> get enabledSorts => _enabledSorts;
  String get currentSort => _currentSort;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSortOptions({bool adminMode = false}) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (adminMode) {
        _allSorts = await _service.getAllSortOptions();
      }
      _enabledSorts = await _service.getAllSortOptions(onlyEnabled: true);

      if (!_enabledSorts.any((s) => s.key == _currentSort) &&
          _enabledSorts.isNotEmpty) {
        final def = _enabledSorts.firstWhere(
          (s) => s.isDefault,
          orElse: () => _enabledSorts.first,
        );
        _currentSort = def.key;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCurrentSort(String key) {
    if (_currentSort == key) return;
    _currentSort = key;
    notifyListeners();
  }

  Future<void> createSortOption({
    required String key,
    required String labelAr,
    required String labelEn,
    int displayOrder = 99,
  }) async {
    await _service.createSortOption(
      key: key,
      labelAr: labelAr,
      labelEn: labelEn,
      displayOrder: displayOrder,
    );
    await fetchSortOptions(adminMode: true);
  }

  Future<void> updateSortOption(String id, Map<String, dynamic> updates) async {
    await _service.updateSortOption(id, updates);
    await fetchSortOptions(adminMode: true);
  }

  Future<void> deleteSortOption(String id) async {
    await _service.deleteSortOption(id);
    await fetchSortOptions(adminMode: true);
  }

  Future<void> setAsDefault(String id) async {
    await _service.setAsDefault(id);
    await fetchSortOptions(adminMode: true);
  }
}

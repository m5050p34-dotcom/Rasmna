import 'package:flutter/material.dart';
import '../models/platform_earning_model.dart';
import '../services/platform_service.dart';

class PlatformProvider extends ChangeNotifier {
  final _service = PlatformService();

  PlatformStats? _stats;
  List<PlatformEarningModel> _earnings = [];
  bool _isLoading = false;
  String? _error;

  PlatformStats? get stats => _stats;
  List<PlatformEarningModel> get earnings => _earnings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getStats(),
        _service.getRecentEarnings(),
      ]);
      _stats = results[0] as PlatformStats;
      _earnings = results[1] as List<PlatformEarningModel>;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

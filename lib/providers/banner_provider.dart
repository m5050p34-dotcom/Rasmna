import 'dart:io';
import 'package:flutter/material.dart';
import '../models/app_settings_model.dart';
import '../models/banner_model.dart';
import '../services/banner_service.dart';

class BannerProvider extends ChangeNotifier {
  final _service = BannerService();

  List<BannerModel> _banners = [];
  AppSettingsModel _settings = AppSettingsModel.defaults();
  bool _isLoading = false;
  String? _error;

  List<BannerModel> get banners => _banners;
  List<BannerModel> get activeBanners =>
      _banners.where((b) => b.isActive).toList();
  AppSettingsModel get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAll({bool adminMode = false}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getBanners(onlyActive: !adminMode),
        _service.getSettings(),
      ]);
      _banners = results[0] as List<BannerModel>;
      _settings = results[1] as AppSettingsModel;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBanner({
    required File file,
    String? title,
    String? linkPhotoId,
    String? linkUrl,                  // 🆕
    int displayOrder = 0,
  }) async {
    final url = await _service.uploadBannerImage(file);
    await _service.addBanner(
      imageUrl: url,
      title: title,
      linkPhotoId: linkPhotoId,
      linkUrl: linkUrl,               // 🆕
      displayOrder: displayOrder,
    );
    await loadAll(adminMode: true);
  }

  Future<void> updateBanner(String id, Map<String, dynamic> updates) async {
    await _service.updateBanner(id, updates);
    await loadAll(adminMode: true);
  }

  Future<void> deleteBanner(String id, String imageUrl) async {
    await _service.deleteBanner(id, imageUrl);
    _banners.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  Future<void> updateSetting(String key, String value) async {
    await _service.updateSetting(key, value);
    await loadAll(adminMode: true);
  }
}

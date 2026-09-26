import 'package:flutter/material.dart';
import '../models/featured_photo_model.dart';
import '../services/featured_service.dart';

class FeaturedProvider extends ChangeNotifier {
  final _service = FeaturedService();

  List<FeaturedPhotoModel> _featured = [];
  bool _isLoading = false;
  String? _error;

  List<FeaturedPhotoModel> get featured => _featured;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFeatured() async {
    _isLoading = true;
    notifyListeners();
    try {
      _featured = await _service.getFeaturedPhotos();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFeatured(String photoId, {int order = 0}) async {
    await _service.addFeatured(photoId, order: order);
    await loadFeatured();
  }

  Future<void> removeFeatured(String featuredId) async {
    await _service.removeFeatured(featuredId);
    _featured.removeWhere((f) => f.id == featuredId);
    notifyListeners();
  }

  Future<void> updateOrder(String featuredId, int newOrder) async {
    await _service.updateOrder(featuredId, newOrder);
    await loadFeatured();
  }

  Future<bool> isFeatured(String photoId) async {
    return await _service.isFeatured(photoId);
  }
}

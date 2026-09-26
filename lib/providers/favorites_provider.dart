import 'package:flutter/material.dart';
import '../models/photo_model.dart';
import '../services/favorites_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final _service = FavoritesService();

  Set<String> _favoriteIds = {};
  List<PhotoModel> _favoritePhotos = [];
  bool _isLoading = false;
  String? _error;

  Set<String> get favoriteIds => _favoriteIds;
  List<PhotoModel> get favoritePhotos => _favoritePhotos;
  bool get isLoading => _isLoading;
  int get count => _favoriteIds.length;
  String? get error => _error;

  bool isFavorited(String photoId) => _favoriteIds.contains(photoId);

  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();
    try {
      _favoritePhotos = await _service.getMyFavorites();
      _favoriteIds = _favoritePhotos.map((p) => p.id).toSet();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleFavorite(String photoId) async {
    final wasFavorited = _favoriteIds.contains(photoId);

    if (wasFavorited) {
      _favoriteIds.remove(photoId);
      _favoritePhotos.removeWhere((p) => p.id == photoId);
    } else {
      _favoriteIds.add(photoId);
    }
    notifyListeners();

    try {
      final isNowFavorited = await _service.toggleFavorite(photoId);

      if (isNowFavorited && !wasFavorited) {
        _reloadQuietly();
      } else if (!isNowFavorited && wasFavorited) {
        _favoritePhotos.removeWhere((p) => p.id == photoId);
      }

      notifyListeners();
      return isNowFavorited;
    } catch (e) {
      if (wasFavorited) {
        _favoriteIds.add(photoId);
      } else {
        _favoriteIds.remove(photoId);
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _reloadQuietly() async {
    try {
      _favoritePhotos = await _service.getMyFavorites();
      _favoriteIds = _favoritePhotos.map((p) => p.id).toSet();
    } catch (_) {}
  }

  void clear() {
    _favoriteIds.clear();
    _favoritePhotos.clear();
    notifyListeners();
  }
}

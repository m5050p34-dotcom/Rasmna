import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/photo_model.dart';
import '../services/photo_service.dart';

class PhotoProvider extends ChangeNotifier {
  final _photoService = PhotoService();

  List<PhotoModel> _photos = [];
  List<PhotoModel> _userPhotos = [];
  List<PhotoModel> _adminPhotos = [];
  List<PhotoModel> _myPurchases = [];
  bool _isLoading = false;
  String? _selectedCategory = 'all';
  String _searchQuery = '';
  String _sortBy = 'newest';
  RealtimeChannel? _channel;

  List<PhotoModel> get photos => _photos;
  List<PhotoModel> get userPhotos => _userPhotos;
  List<PhotoModel> get adminPhotos => _adminPhotos;
  List<PhotoModel> get myPurchases => _myPurchases;
  bool get isLoading => _isLoading;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;

  Future<void> fetchPhotos({String? category, String? sortBy}) async {
    _isLoading = true;
    if (category != null) _selectedCategory = category;
    if (sortBy != null) _sortBy = sortBy;
    notifyListeners();
    try {
      _photos = await _photoService.getPhotos(
        category: _selectedCategory,
        searchQuery: _searchQuery,
        sortBy: _sortBy,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    await fetchPhotos();
  }

  Future<void> fetchUserPhotos(String userId) async {
    _userPhotos = await _photoService.getUserPhotos(userId);
    notifyListeners();
  }

  Future<void> fetchMyPurchases() async {
    _myPurchases = await _photoService.getMyPurchases();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════
  // 🆕 للأدمن: جلب كل الصور
  // ═══════════════════════════════════════════════
  Future<void> fetchAdminPhotos({String? category}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _adminPhotos = await _photoService.getPhotos(
        category: category,
        limit: 500,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadPhoto({
    required File file,
    required String title,
    required String category,
    required double price,
    required String format,
    required String userId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final photo = await _photoService.uploadPhoto(
        file: file,
        title: title,
        category: category,
        price: price,
        format: format,
      );
      _photos.insert(0, photo);
      _userPhotos.insert(0, photo);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePhoto({
    required String photoId,
    String? title,
    String? category,
    double? price,
  }) async {
    final updated = await _photoService.updatePhoto(
      photoId: photoId,
      title: title,
      category: category,
      price: price,
    );
    _replace(updated);
    notifyListeners();
  }

  void _replace(PhotoModel updated) {
    final idx = _photos.indexWhere((p) => p.id == updated.id);
    if (idx != -1) _photos[idx] = updated;
    final uIdx = _userPhotos.indexWhere((p) => p.id == updated.id);
    if (uIdx != -1) _userPhotos[uIdx] = updated;
    final aIdx = _adminPhotos.indexWhere((p) => p.id == updated.id);
    if (aIdx != -1) _adminPhotos[aIdx] = updated;
  }

  Future<void> deletePhoto({
    required String photoId,
    required String imageUrl,
  }) async {
    await _photoService.deletePhoto(photoId: photoId, imageUrl: imageUrl);
    _photos.removeWhere((p) => p.id == photoId);
    _userPhotos.removeWhere((p) => p.id == photoId);
    _adminPhotos.removeWhere((p) => p.id == photoId);
    notifyListeners();
  }

  void subscribeToRealtime() {
    _channel = Supabase.instance.client
        .channel('photos-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'photos',
          callback: (_) => fetchPhotos(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

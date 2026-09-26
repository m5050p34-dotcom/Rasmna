import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';

enum UserFilter { all, admins, banned }

class UserProvider extends ChangeNotifier {
  final _service = ProfileService();
  List<ProfileModel> _users = [];
  bool _isLoading = false;
  String _searchQuery = '';
  UserFilter _filter = UserFilter.all;
  String? _error;

  List<ProfileModel> get users => _users;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  UserFilter get filter => _filter;
  String? get error => _error;

  Future<void> fetchUsers({String? search, UserFilter? filter}) async {
    _isLoading = true;
    if (search != null) _searchQuery = search;
    if (filter != null) _filter = filter;
    notifyListeners();
    try {
      _users = await _service.getAllProfiles(
        searchQuery: _searchQuery,
        onlyAdmins: _filter == UserFilter.admins,
        onlyBanned: _filter == UserFilter.banned,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setBanned(String userId, bool banned) async {
    await _service.setBanned(userId, banned);
    await _fetchSilently();
  }

  Future<void> setAdmin(String userId, bool isAdmin) async {
    await _service.setAdmin(userId, isAdmin);
    await _fetchSilently();
  }

  Future<void> _fetchSilently() async {
    try {
      _users = await _service.getAllProfiles(
        searchQuery: _searchQuery,
        onlyAdmins: _filter == UserFilter.admins,
        onlyBanned: _filter == UserFilter.banned,
      );
      notifyListeners();
    } catch (_) {}
  }

  void updateUserPoints(String userId, int newPoints) {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      _users[idx] = _users[idx].copyWith(points: newPoints);
      notifyListeners();
    }
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/screen_security_service.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();
  final _profileService = ProfileService();

  ProfileModel? _profile;
  bool _isLoading = true;
  String? _error;
  StreamSubscription<AuthState>? _authSub;

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authService.isAuthenticated;
  bool get isAdmin => _profile?.isAdmin ?? false;
  bool get isBanned => _profile?.isBanned ?? false;
  String? get error => _error;
  String? get userId => _authService.currentUserId;

  String? get activeIconUrl => _profile?.activeIconUrl;
  bool get hasActiveIcon => _profile?.hasActiveIcon ?? false;
  int get activeIconDaysRemaining =>
      _profile?.activeIconDaysRemaining ?? 0;
  bool get isActiveIconExpiringSoon =>
      _profile?.isActiveIconExpiringSoon ?? false;

  AuthProvider() {
    _init();
  }

  void _init() {
    if (_authService.isAuthenticated) {
      _loadProfile(_authService.currentUserId!);
    } else {
      _isLoading = false;
      ScreenSecurityService.blockScreenshots();
      notifyListeners();
    }

    _authSub = _authService.authStateChanges.listen((data) {
      final session = data.session;
      if (session != null) {
        _loadProfile(session.user.id);
      } else {
        _profile = null;
        _isLoading = false;
        _error = null;
        ScreenSecurityService.blockScreenshots();
        notifyListeners();
      }
    });
  }

  Future<void> _loadProfile(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();
      _profile = await _profileService.getProfile(userId);
      _error = null;
      await ScreenSecurityService.applyPolicy(isAdmin: isAdmin);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      await _authService.signIn(email: email, password: password);
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String username) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      await _authService.signUp(
        email: email,
        password: password,
        username: username,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════
  // ✅ signOut مُحصّن ضد الأخطاء
  // ═══════════════════════════════════════════════
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      debugPrint('⚠️ signOut error: $e');
    }

    // إعادة ضبط كامل
    _profile = null;
    _isLoading = false;
    _error = null;

    try {
      await ScreenSecurityService.blockScreenshots();
    } catch (e) {
      debugPrint('⚠️ blockScreenshots error: $e');
    }

    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final uid = _authService.currentUserId;
    if (uid != null) {
      _profile = await _profileService.getProfile(uid);
      await ScreenSecurityService.applyPolicy(isAdmin: isAdmin);
      notifyListeners();
    }
  }

  Future<void> refreshAfterPurchase() async {
    await refreshProfile();
  }

  void clearExpiredIconLocally() {
    if (_profile == null) return;
    if (_profile!.activeIconUrl == null) return;
    if (!_profile!.hasActiveIcon) {
      _profile = _profile!.copyWith(clearActiveIcon: true);
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  Future<DailyRewardResult?> claimDailyReward() async {
    final uid = _authService.currentUserId;
    if (uid == null) return null;
    final result = await _profileService.claimDailyReward(uid);
    await refreshProfile();
    return result;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

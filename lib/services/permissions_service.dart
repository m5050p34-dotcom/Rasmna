import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionsService {
  static const String _keyFirstLaunch = 'first_launch_done';
  static const String _keyNotifAsked = 'notifications_asked';
  static const String _keyNotifGranted = 'notifications_granted';

  // ═══════════════════════════════════════════════
  // أول مرة؟
  // ═══════════════════════════════════════════════
  static Future<bool> isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(_keyFirstLaunch) ?? false);
    } catch (e) {
      debugPrint('⚠️ isFirstLaunch error: $e');
      return false;
    }
  }

  static Future<void> markFirstLaunchDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyFirstLaunch, true);
    } catch (_) {}
  }

  static Future<bool> hasAskedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyNotifAsked) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markNotificationsAsked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyNotifAsked, true);
    } catch (_) {}
  }

  static Future<bool> isNotificationsGranted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyNotifGranted) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setNotificationsGranted(bool granted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyNotifGranted, granted);
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════
  // طلب الإذونات
  // ═══════════════════════════════════════════════
  static Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      final granted = status.isGranted;
      await setNotificationsGranted(granted);
      debugPrint('🔔 Notification permission: $granted');
      return granted;
    } catch (e) {
      debugPrint('❌ Notification permission error: $e');
      return false;
    }
  }

  static Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestStoragePermission() async {
    try {
      if (await Permission.photos.isGranted) return true;
      final photos = await Permission.photos.request();
      if (photos.isGranted) return true;
      final storage = await Permission.storage.request();
      return storage.isGranted;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{};
    results['notifications'] = await requestNotificationPermission();
    results['camera'] = await requestCameraPermission();
    results['storage'] = await requestStoragePermission();
    debugPrint('📋 Permissions: $results');
    return results;
  }

  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}

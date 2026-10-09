import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// أنواع أصوات الإشعارات
enum NotificationSound {
  defaultSound,
  bell,
  soft,
  silent,
}

extension NotificationSoundInfo on NotificationSound {
  String get key {
    switch (this) {
      case NotificationSound.defaultSound: return 'default';
      case NotificationSound.bell:         return 'bell';
      case NotificationSound.soft:         return 'soft';
      case NotificationSound.silent:       return 'silent';
    }
  }

  String get arabicName {
    switch (this) {
      case NotificationSound.defaultSound: return 'افتراضي';
      case NotificationSound.bell:         return 'جرس';
      case NotificationSound.soft:         return 'هادئ';
      case NotificationSound.silent:       return 'صامت';
    }
  }

  String get description {
    switch (this) {
      case NotificationSound.defaultSound: return 'الصوت الافتراضي للنظام';
      case NotificationSound.bell:         return 'صوت جرس واضح';
      case NotificationSound.soft:         return 'نبرة هادئة';
      case NotificationSound.silent:       return 'بدون صوت';
    }
  }

  bool get playSound => this != NotificationSound.silent;

  /// اسم ملف الصوت في raw (Android)
  String? get rawSound {
    switch (this) {
      case NotificationSound.defaultSound: return null;
      case NotificationSound.bell:         return 'bell';
      case NotificationSound.soft:         return 'soft';
      case NotificationSound.silent:       return null;
    }
  }
}

/// خدمة إدارة صوت الإشعارات
class NotificationSoundService {
  static const String _prefsKey = 'notification_sound_preference';
  static NotificationSound _current = NotificationSound.defaultSound;

  static NotificationSound get current => _current;

  /// تحميل الإعداد المحفوظ
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString(_prefsKey) ?? 'default';
      _current = _parse(key);
      debugPrint('🔔 Sound loaded: ${_current.key}');
    } catch (e) {
      debugPrint('⚠️ load sound error: $e');
    }
  }

  /// حفظ الإعداد الجديد
  static Future<void> setSound(NotificationSound sound) async {
    try {
      _current = sound;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, sound.key);
      debugPrint('🔔 Sound saved: ${sound.key}');
    } catch (e) {
      debugPrint('⚠️ set sound error: $e');
    }
  }

  static NotificationSound _parse(String key) {
    switch (key) {
      case 'bell':   return NotificationSound.bell;
      case 'soft':   return NotificationSound.soft;
      case 'silent': return NotificationSound.silent;
      default:       return NotificationSound.defaultSound;
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ScreenSecurityService {
  static const _channel = MethodChannel('com.rasmna.rasmna/screen_security');

  /// 🔒 منع لقطات الشاشة
  static Future<void> blockScreenshots() async {
    try {
      await _channel.invokeMethod('enable');
      debugPrint('🔒 Screenshots BLOCKED');
    } catch (e) {
      debugPrint('⚠️ Could not block screenshots: $e');
    }
  }

  /// 📸 السماح بلقطات الشاشة
  static Future<void> allowScreenshots() async {
    try {
      await _channel.invokeMethod('disable');
      debugPrint('📸 Screenshots ALLOWED');
    } catch (e) {
      debugPrint('⚠️ Could not allow screenshots: $e');
    }
  }

  /// ⚙️ ضبط الحالة بناءً على نوع المستخدم
  /// - الأدمن → مسموح
  /// - المستخدم العادي → ممنوع
  static Future<void> applyPolicy({required bool isAdmin}) async {
    if (isAdmin) {
      await allowScreenshots();
    } else {
      await blockScreenshots();
    }
  }
}

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationsService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ✅ عدّاد فريد لكل إشعار (يمنع التعارض)
  static int _notificationCounter = 0;

  static const String _channelId = 'rasmna_notifications';
  static const String _channelName = 'إشعارات رسمنا';
  static const String _channelDesc = 'إشعارات المتابعة والمبيعات والمكافآت';

  // ═══════════════════════════════════════════════
  // 🚀 التهيئة
  // ═══════════════════════════════════════════════
  static Future<void> initialize({
    void Function(String? payload)? onTap,
  }) async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('🔔 Notification tapped: ${response.payload}');
        onTap?.call(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: (response) {
        debugPrint('🔔 Background notification: ${response.payload}');
      },
    );

    await _createChannel();
    debugPrint('✅ LocalNotifications initialized');
  }

  static Future<void> _createChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint('✅ Notification channel created');
  }

  // ═══════════════════════════════════════════════
  // 📢 إظهار إشعار (مع ID فريد)
  // ═══════════════════════════════════════════════
  static Future<void> show({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    if (!_initialized) await initialize();

    // ✅ ID فريد مضمون:
    // - إذا مُرّر، نستخدمه
    // - إذا لا، نستخدم counter + timestamp
    final notificationId = id ??
        (++_notificationCounter +
            DateTime.now().millisecondsSinceEpoch.remainder(1000000));

    debugPrint('📢 Showing notification ID: $notificationId');

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      enableLights: true,
      color: const Color(0xFF6C63FF),
      colorized: true,
      styleInformation: const BigTextStyleInformation(''),
      visibility: NotificationVisibility.public,
      autoCancel: true,
      ongoing: false,
      category: AndroidNotificationCategory.message,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );
      debugPrint('✅ Notification shown: $title');
    } catch (e) {
      debugPrint('❌ Show notification error: $e');
    }
  }

  static Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

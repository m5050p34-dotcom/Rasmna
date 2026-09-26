import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/local_notifications_service.dart';
import '../services/notifications_service.dart';

class NotificationsProvider extends ChangeNotifier {
  final _service = NotificationsService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  bool _subscribed = false;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  // ✅ تتبع الإشعارات التي شوهدت (لمنع التكرار)
  final Set<String> _seenIds = {};

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUnread => _unreadCount > 0;

  // ═══════════════════════════════════════════════
  // تحميل الإشعارات (بدون إظهار إشعارات النظام)
  // ═══════════════════════════════════════════════
  Future<void> loadAll({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        _service.getMyNotifications(),
        _service.getUnreadCount(),
      ]);
      _notifications = results[0] as List<NotificationModel>;
      _unreadCount = results[1] as int;
      _error = null;

      // ✅ سجّل كل الإشعارات الحالية كـ "شوهدت" (لأنها قديمة)
      for (final n in _notifications) {
        _seenIds.add(n.id);
      }

      debugPrint('📬 Loaded: ${_notifications.length} (unread: $_unreadCount)');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ loadAll error: $e');
    } finally {
      if (!silent) _isLoading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════
  // 🔔 Realtime + إظهار الإشعارات الجديدة فقط
  // ═══════════════════════════════════════════════
  void subscribeRealtime() {
    if (_subscribed) return;
    _subscribed = true;

    debugPrint('🔔 Subscribing to notifications realtime...');

    _subscription?.cancel();
    _subscription = _service.streamMyNotifications().listen(
      (list) {
        debugPrint('🔔 Realtime fired: ${list.length} notifications');

        final newNotifications = list
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        // ✅ ابحث عن الجديدة فقط
        final freshOnes = <NotificationModel>[];
        for (final n in newNotifications) {
          if (!_seenIds.contains(n.id)) {
            _seenIds.add(n.id);
            freshOnes.add(n);
          }
        }

        // ✅ أظهر إشعارات النظام للجديدة فقط
        for (final n in freshOnes) {
          debugPrint('🆕 New notification: ${n.title}');
          _showSystemNotification(n);
        }

        _notifications = newNotifications;
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('❌ Realtime error: $e');
        _subscribed = false;
      },
    );
  }

  // ═══════════════════════════════════════════════
  // 📢 إظهار إشعار النظام
  // ═══════════════════════════════════════════════
  void _showSystemNotification(NotificationModel n) {
    LocalNotificationsService.show(
      title: n.title,
      body: n.body,
      payload: n.id,
      // ✅ لا نمرّر ID — سيُنشأ فريد تلقائياً
    );
  }

  // ═══════════════════════════════════════════════
  // ✅ تسجيل كمقروء
  // ═══════════════════════════════════════════════
  Future<void> markAsRead(String id) async {
    await _service.markAsRead(id);
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx] = NotificationModel(
        id: _notifications[idx].id,
        userId: _notifications[idx].userId,
        type: _notifications[idx].type,
        title: _notifications[idx].title,
        body: _notifications[idx].body,
        data: _notifications[idx].data,
        isRead: true,
        createdAt: _notifications[idx].createdAt,
      );
      _unreadCount = (_unreadCount - 1).clamp(0, 999);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    await _service.markAllAsRead();
    _unreadCount = 0;
    _notifications = _notifications
        .map((n) => NotificationModel(
              id: n.id,
              userId: n.userId,
              type: n.type,
              title: n.title,
              body: n.body,
              data: n.data,
              isRead: true,
              createdAt: n.createdAt,
            ))
        .toList();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _service.deleteNotification(id);
    final wasUnread = _notifications.any((n) => n.id == id && !n.isRead);
    _notifications.removeWhere((n) => n.id == id);
    _seenIds.remove(id);
    if (wasUnread) _unreadCount = (_unreadCount - 1).clamp(0, 999);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════
  // للأدمن
  // ═══════════════════════════════════════════════
  Future<int> adminSend({
    required String title,
    required String body,
    required String target,
  }) async {
    final count = await _service.adminSendNotification(
      title: title,
      body: body,
      target: target,
    );
    await loadAll(silent: true);
    return count;
  }

  Future<void> adminSendToUser({
    required String userId,
    required String title,
    required String body,
  }) async {
    await _service.adminSendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
    );
  }

  void clear() {
    _subscription?.cancel();
    _subscribed = false;
    _notifications = [];
    _unreadCount = 0;
    _seenIds.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

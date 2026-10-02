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

  final Set<String> _seenIds = {};

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUnread => _unreadCount > 0;

  // ═══════════════════════════════════════════════
  // ✅ قائمة مرتبة: غير المقروء أولاً، ثم المقروء
  //    (كلاهما من الأحدث للأقدم)
  // ═══════════════════════════════════════════════
  List<NotificationModel> get sortedNotifications {
    final unread = _notifications.where((n) => !n.isRead).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final read = _notifications.where((n) => n.isRead).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return [...unread, ...read];
  }

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

  void subscribeRealtime() {
    if (_subscribed) {
      debugPrint('🔔 Already subscribed - skipping');
      return;
    }
    _subscribed = true;
    debugPrint('🔔 Subscribing to notifications realtime...');

    _subscription?.cancel();
    _subscription = _service.streamMyNotifications().listen(
      (list) {
        debugPrint('🔔 Realtime fired: ${list.length} notifications');
        final newNotifications =
            list.map((json) => NotificationModel.fromJson(json)).toList();

        final freshOnes = <NotificationModel>[];
        for (final n in newNotifications) {
          if (!_seenIds.contains(n.id)) {
            _seenIds.add(n.id);
            freshOnes.add(n);
          }
        }

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
      cancelOnError: false,
    );
  }

  Future<void> reconnect() async {
    debugPrint('🔌 Reconnecting notifications realtime...');
    _subscription?.cancel();
    _subscribed = false;
    await loadAll(silent: true);
    subscribeRealtime();
  }

  void _showSystemNotification(NotificationModel n) {
    LocalNotificationsService.show(
      title: n.title,
      body: n.body,
      payload: n.id,
    );
  }

  Future<void> markAsRead(String id) async {
    await _service.markAsRead(id);
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      final old = _notifications[idx];
      _notifications[idx] = NotificationModel(
        id: old.id,
        userId: old.userId,
        type: old.type,
        title: old.title,
        body: old.body,
        data: old.data,
        isRead: true,
        createdAt: old.createdAt,
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
  // 🗑️ حذف جميع الإشعارات
  // ═══════════════════════════════════════════════
  Future<void> deleteAll() async {
    await _service.deleteAllNotifications();
    _notifications = [];
    _unreadCount = 0;
    _seenIds.clear();
    notifyListeners();
  }

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

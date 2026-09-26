import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ═══════════════════════════════════════════════
  // جلب الإشعارات
  // ═══════════════════════════════════════════════
  Future<List<NotificationModel>> getMyNotifications({int limit = 50}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('⚠️ getMyNotifications: no user');
      return [];
    }

    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      final list = response as List;
      debugPrint('📬 Loaded ${list.length} notifications');
      return list
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ getMyNotifications error: $e');
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);
      final count = (response as List).length;
      debugPrint('📬 Unread: $count');
      return count;
    } catch (e) {
      debugPrint('❌ getUnreadCount error: $e');
      return 0;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true}).eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase
        .from('notifications')
        .update({'is_read': true}).eq('user_id', userId);
  }

  Future<void> deleteNotification(String id) async {
    await _supabase.from('notifications').delete().eq('id', id);
  }

  // ═══════════════════════════════════════════════
  // إرسال إشعار (عبر RPC)
  // ═══════════════════════════════════════════════
  Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.rpc('send_notification_internal', params: {
        'p_user_id': userId,
        'p_type': type,
        'p_title': title,
        'p_body': body,
        'p_data': data ?? {},
      });
      debugPrint('✅ Notification sent to $userId');
    } catch (e) {
      debugPrint('❌ sendNotification error: $e');
    }
  }

  // ═══════════════════════════════════════════════
  // إرسال إشعار جماعي (للأدمن)
  // ═══════════════════════════════════════════════
  Future<int> adminSendNotification({
    required String title,
    required String body,
    required String target,
  }) async {
    final response = await _supabase.rpc('admin_send_notification', params: {
      'p_title': title,
      'p_body': body,
      'p_target': target,
    });
    return (response as num).toInt();
  }

  // ═══════════════════════════════════════════════
  // إرسال إشعار لمستخدم محدد (للأدمن)
  // ═══════════════════════════════════════════════
  Future<void> adminSendNotificationToUser({
    required String userId,
    required String title,
    required String body,
  }) async {
    await _supabase.rpc('admin_send_notification_to_user', params: {
      'p_user_id': userId,
      'p_title': title,
      'p_body': body,
    });
  }

  // ═══════════════════════════════════════════════
  // Realtime Stream
  // ═══════════════════════════════════════════════
  Stream<List<Map<String, dynamic>>> streamMyNotifications() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map((list) => list.reversed.toList());
  }
}

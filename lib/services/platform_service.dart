import 'package:supabase_flutter/supabase_flutter.dart';

class PlatformService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// إحصائيات شاملة (RPC)
  Future<Map<String, int>> getStats() async {
    try {
      final result = await _supabase.rpc('get_platform_stats');
      final map = Map<String, dynamic>.from(result as Map);
      return {
        'total':          (map['total'] as num?)?.toInt() ?? 0,
        'icons':          (map['icons'] as num?)?.toInt() ?? 0,
        'photos':         (map['photos'] as num?)?.toInt() ?? 0,
        'username':       (map['username'] as num?)?.toInt() ?? 0,
        'avatar':         (map['avatar'] as num?)?.toInt() ?? 0,
        'commission':     (map['commission'] as num?)?.toInt() ?? 0,
        'today':          (map['today'] as num?)?.toInt() ?? 0,
        'week':           (map['week'] as num?)?.toInt() ?? 0,
        'month':          (map['month'] as num?)?.toInt() ?? 0,
        'count':          (map['count'] as num?)?.toInt() ?? 0,
        'admin_balance':  (map['admin_balance'] as num?)?.toInt() ?? 0,
      };
    } catch (e) {
      return {
        'total': 0, 'icons': 0, 'photos': 0,
        'username': 0, 'avatar': 0, 'commission': 0,
        'today': 0, 'week': 0, 'month': 0,
        'count': 0, 'admin_balance': 0,
      };
    }
  }

  /// جلب الإيرادات (مع تصفية اختيارية)
  Future<List<Map<String, dynamic>>> getEarnings({
    String? source,
    int limit = 100,
  }) async {
    try {
      dynamic query = _supabase
          .from('platform_earnings')
          .select();

      if (source != null && source.isNotEmpty && source != 'all') {
        query = query.eq('source', source);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      return [];
    }
  }

  /// alias للتوافق مع PlatformProvider
  Future<List<Map<String, dynamic>>> getRecentEarnings({int limit = 50}) {
    return getEarnings(limit: limit);
  }

  /// إحصائيات يومية (آخر 7 أيام)
  Future<List<Map<String, dynamic>>> getDailyStats() async {
    try {
      final response = await _supabase
          .from('platform_earnings')
          .select('amount, created_at')
          .gte(
            'created_at',
            DateTime.now()
                .subtract(const Duration(days: 7))
                .toIso8601String(),
          );

      final list = response as List;

      // تجميع حسب اليوم
      final Map<String, int> grouped = {};
      for (final item in list) {
        final date = DateTime.parse(item['created_at'] as String);
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        grouped[key] = (grouped[key] ?? 0) + ((item['amount'] as num).toInt());
      }

      // ترتيب تصاعدي
      final sortedKeys = grouped.keys.toList()..sort();

      return sortedKeys
          .map((k) => {'date': k, 'amount': grouped[k]})
          .toList();
    } catch (e) {
      return [];
    }
  }
}

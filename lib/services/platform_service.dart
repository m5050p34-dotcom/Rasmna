import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/platform_earning_model.dart';

class PlatformService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// إحصائيات أرباح المنصة
  Future<PlatformStats> getStats() async {
    final response = await _supabase.rpc('get_platform_stats');
    return PlatformStats.fromJson(response as Map<String, dynamic>);
  }

  /// آخر العمولات (للأدمن)
  Future<List<PlatformEarningModel>> getRecentEarnings({
    int limit = 50,
  }) async {
    final response = await _supabase
        .from('platform_earnings')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => PlatformEarningModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rating_model.dart';

class RatingsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// إحصائيات صورة (تقييمات + تعليقات + مفضلة)
  Future<PhotoStats> getPhotoStats(String photoId) async {
    try {
      final response = await _supabase.rpc(
        'get_photo_stats',
        params: {'p_photo_id': photoId},
      );
      return PhotoStats.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return PhotoStats.empty();
    }
  }

  /// إضافة/تحديث تقييم
  Future<void> ratePhoto({
    required String photoId,
    required int rating,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    if (rating < 1 || rating > 5) throw Exception('Invalid rating');

    await _supabase.from('ratings').upsert(
      {
        'photo_id': photoId,
        'user_id': userId,
        'rating': rating,
      },
      onConflict: 'photo_id,user_id',
    );
  }

  /// حذف تقييم
  Future<void> removeRating(String photoId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase
        .from('ratings')
        .delete()
        .eq('photo_id', photoId)
        .eq('user_id', userId);
  }
}

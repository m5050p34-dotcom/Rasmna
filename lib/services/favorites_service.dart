import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/photo_model.dart';

class FavoritesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> isFavorited(String photoId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final result = await _supabase
          .from('favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('photo_id', photoId)
          .maybeSingle();
      return result != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleFavorite(String photoId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final isFav = await isFavorited(photoId);
    if (isFav) {
      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('photo_id', photoId);
      return false;
    } else {
      await _supabase.from('favorites').insert({
        'user_id': userId,
        'photo_id': photoId,
      });
      return true;
    }
  }

  Future<List<PhotoModel>> getMyFavorites() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('favorites')
        .select(
          'photo_id, photos:photo_id(*, '
          'profiles:user_id(id, username, email, avatar_url, is_admin))',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .where((e) => e['photos'] != null)
        .map((e) => PhotoModel.fromJson(e['photos'] as Map<String, dynamic>))
        .toList();
  }
}

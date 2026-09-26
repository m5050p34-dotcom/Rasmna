import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/featured_photo_model.dart';

class FeaturedService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<FeaturedPhotoModel>> getFeaturedPhotos() async {
    final response = await _supabase
        .from('featured_photos')
        .select(
          '*, photos:photo_id(*, profiles:user_id(id, username, email, avatar_url, is_admin))',
        )
        .order('display_order', ascending: true)
        .order('created_at', ascending: false);

    return (response as List)
        .where((e) => e['photos'] != null)
        .map((e) => FeaturedPhotoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addFeatured(String photoId, {int order = 0}) async {
    final userId = _supabase.auth.currentUser?.id;
    await _supabase.from('featured_photos').insert({
      'photo_id': photoId,
      'display_order': order,
      'added_by': userId,
    });
  }

  Future<void> removeFeatured(String featuredId) async {
    await _supabase.from('featured_photos').delete().eq('id', featuredId);
  }

  Future<void> updateOrder(String featuredId, int newOrder) async {
    await _supabase
        .from('featured_photos')
        .update({'display_order': newOrder}).eq('id', featuredId);
  }

  Future<bool> isFeatured(String photoId) async {
    try {
      final response = await _supabase
          .from('featured_photos')
          .select('id')
          .eq('photo_id', photoId)
          .maybeSingle();
      return response != null;
    } catch (_) {
      return false;
    }
  }
}

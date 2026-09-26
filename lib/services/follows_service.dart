import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class FollowsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ═══════════════════════════════════════════════
  // إحصائيات المصور
  // ═══════════════════════════════════════════════
  Future<PhotographerStats> getPhotographerStats(String userId) async {
    try {
      final response = await _supabase.rpc(
        'get_photographer_stats',
        params: {'p_user_id': userId},
      );
      return PhotographerStats.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('getPhotographerStats error: $e');
      return PhotographerStats.empty();
    }
  }

  // ═══════════════════════════════════════════════
  // تبديل المتابعة
  // ═══════════════════════════════════════════════
  Future<bool> toggleFollow(String targetUserId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    if (userId == targetUserId) throw Exception('لا يمكنك متابعة نفسك');

    final existing = await _supabase
        .from('follows')
        .select('id')
        .eq('follower_id', userId)
        .eq('following_id', targetUserId)
        .maybeSingle();

    if (existing != null) {
      await _supabase.from('follows').delete().eq('id', existing['id']);
      return false;
    } else {
      await _supabase.from('follows').insert({
        'follower_id': userId,
        'following_id': targetUserId,
      });
      return true;
    }
  }

  // ═══════════════════════════════════════════════
  // جلب المتابعين (استعلام مباشر)
  // ═══════════════════════════════════════════════
  Future<List<ProfileModel>> getFollowers(String userId) async {
    try {
      debugPrint('📥 getFollowers for: $userId');

      final followsResponse = await _supabase
          .from('follows')
          .select('follower_id')
          .eq('following_id', userId)
          .order('created_at', ascending: false);

      final followerIds = (followsResponse as List)
          .map((e) => e['follower_id'] as String)
          .toList();

      debugPrint('📥 Found ${followerIds.length} followers');

      if (followerIds.isEmpty) return [];

      final profilesResponse = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', followerIds);

      final profiles = (profilesResponse as List)
          .map((e) => ProfileModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final orderedProfiles = <ProfileModel>[];
      for (final id in followerIds) {
        for (final p in profiles) {
          if (p.id == id) {
            orderedProfiles.add(p);
            break;
          }
        }
      }

      debugPrint('📥 Returning ${orderedProfiles.length} profiles');
      return orderedProfiles;
    } catch (e) {
      debugPrint('❌ getFollowers error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════
  // جلب المتابَعين (استعلام مباشر)
  // ═══════════════════════════════════════════════
  Future<List<ProfileModel>> getFollowing(String userId) async {
    try {
      debugPrint('📥 getFollowing for: $userId');

      final followsResponse = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId)
          .order('created_at', ascending: false);

      final followingIds = (followsResponse as List)
          .map((e) => e['following_id'] as String)
          .toList();

      debugPrint('📥 Found ${followingIds.length} following');

      if (followingIds.isEmpty) return [];

      final profilesResponse = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', followingIds);

      final profiles = (profilesResponse as List)
          .map((e) => ProfileModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final orderedProfiles = <ProfileModel>[];
      for (final id in followingIds) {
        for (final p in profiles) {
          if (p.id == id) {
            orderedProfiles.add(p);
            break;
          }
        }
      }

      debugPrint('📥 Returning ${orderedProfiles.length} profiles');
      return orderedProfiles;
    } catch (e) {
      debugPrint('❌ getFollowing error: $e');
      return [];
    }
  }
}

// ═══════════════════════════════════════════════
// نموذج الإحصائيات
// ═══════════════════════════════════════════════
class PhotographerStats {
  final int photosCount;
  final int followersCount;
  final int followingCount;
  final int totalSales;
  final bool isFollowing;

  PhotographerStats({
    required this.photosCount,
    required this.followersCount,
    required this.followingCount,
    required this.totalSales,
    required this.isFollowing,
  });

  factory PhotographerStats.fromJson(Map<String, dynamic> json) {
    return PhotographerStats(
      photosCount: (json['photos_count'] ?? 0) as int,
      followersCount: (json['followers_count'] ?? 0) as int,
      followingCount: (json['following_count'] ?? 0) as int,
      totalSales: (json['total_sales'] ?? 0) as int,
      isFollowing: (json['is_following'] ?? false) as bool,
    );
  }

  static PhotographerStats empty() => PhotographerStats(
        photosCount: 0,
        followersCount: 0,
        followingCount: 0,
        totalSales: 0,
        isFollowing: false,
      );
}

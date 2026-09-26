import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment_model.dart';

class CommentsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<CommentModel>> getPhotoComments(
    String photoId, {
    int limit = 100,
  }) async {
    final response = await _supabase
        .from('comments')
        .select(
          '*, profiles:user_id(id, username, email, avatar_url, is_admin)',
        )
        .eq('photo_id', photoId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommentModel> addComment({
    required String photoId,
    required String content,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final trimmed = content.trim();
    if (trimmed.isEmpty) throw Exception('التعليق فارغ');
    if (trimmed.length > 500) throw Exception('التعليق طويل جداً');

    final response = await _supabase
        .from('comments')
        .insert({
          'photo_id': photoId,
          'user_id': userId,
          'content': trimmed,
        })
        .select(
          '*, profiles:user_id(id, username, email, avatar_url, is_admin)',
        )
        .single();

    return CommentModel.fromJson(response);
  }

  Future<void> updateComment(String commentId, String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) throw Exception('التعليق فارغ');

    await _supabase.from('comments').update({
      'content': trimmed,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', commentId);
  }

  Future<void> deleteComment(String commentId) async {
    await _supabase.from('comments').delete().eq('id', commentId);
  }

  /// Stream Realtime للتعليقات
  Stream<List<Map<String, dynamic>>> streamComments(String photoId) {
    return _supabase
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('photo_id', photoId)
        .order('created_at')
        .map((list) => list.reversed.toList());
  }
}

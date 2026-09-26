import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/banner_model.dart';
import '../models/app_settings_model.dart';

class BannerService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // ═══════════════════════════════════════════════
  // جلب البانرات
  // ═══════════════════════════════════════════════
  Future<List<BannerModel>> getBanners({bool onlyActive = true}) async {
    var query = _supabase
        .from('banners')
        .select(
          '*, photos:link_photo_id(*, profiles:user_id(id, username, email, avatar_url))',
        );

    if (onlyActive) query = query.eq('is_active', true);

    final response = await query
        .order('display_order', ascending: true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════════════════════════════════
  // رفع صورة بانر
  // ═══════════════════════════════════════════════
  Future<String> uploadBannerImage(File file) async {
    final fileName = '${_uuid.v4()}.jpg';
    await _supabase.storage.from('banners').upload(
          fileName,
          file,
          fileOptions: const FileOptions(upsert: false),
        );
    return _supabase.storage.from('banners').getPublicUrl(fileName);
  }

  // ═══════════════════════════════════════════════
  // إضافة بانر (مع الرابط)
  // ═══════════════════════════════════════════════
  Future<BannerModel> addBanner({
    required String imageUrl,
    String? title,
    String? linkPhotoId,
    String? linkUrl,                    // 🆕
    int displayOrder = 0,
  }) async {
    final response = await _supabase
        .from('banners')
        .insert({
          'image_url': imageUrl,
          'title': title,
          'link_photo_id': linkPhotoId,
          'link_url': linkUrl,          // 🆕
          'display_order': displayOrder,
        })
        .select()
        .single();
    return BannerModel.fromJson(response);
  }

  // ═══════════════════════════════════════════════
  // تعديل بانر
  // ═══════════════════════════════════════════════
  Future<void> updateBanner(String id, Map<String, dynamic> updates) async {
    await _supabase.from('banners').update(updates).eq('id', id);
  }

  // ═══════════════════════════════════════════════
  // حذف بانر
  // ═══════════════════════════════════════════════
  Future<void> deleteBanner(String id, String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      final bannersIndex = segments.indexOf('banners');
      if (bannersIndex != -1) {
        final filePath = segments.sublist(bannersIndex + 1).join('/');
        await _supabase.storage.from('banners').remove([filePath]);
      }
    } catch (_) {}
    await _supabase.from('banners').delete().eq('id', id);
  }

  // ═══════════════════════════════════════════════
  // جلب الإعدادات
  // ═══════════════════════════════════════════════
  Future<AppSettingsModel> getSettings() async {
    try {
      final response = await _supabase.from('app_settings').select();
      final map = <String, String>{};
      for (final row in (response as List)) {
        map[row['key'] as String] = row['value'] as String;
      }
      return AppSettingsModel.fromMap(map);
    } catch (_) {
      return AppSettingsModel.defaults();
    }
  }

  // ═══════════════════════════════════════════════
  // تحديث إعداد
  // ═══════════════════════════════════════════════
  Future<void> updateSetting(String key, String value) async {
    await _supabase.from('app_settings').upsert({
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}

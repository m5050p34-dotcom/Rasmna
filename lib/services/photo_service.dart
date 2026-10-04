import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../models/photo_model.dart';

class PhotoService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // ═══════════════════════════════════════════════
  // 🎨 ضغط الصورة
  // ═══════════════════════════════════════════════
  Future<File> _compressImage(File file, String format) async {
    try {
      final lowerFormat = format.toLowerCase();
      final isPng = lowerFormat == 'png';
      final isWebp = lowerFormat == 'webp';

      if (isPng || isWebp) {
        return await _compressPreservingAlpha(file, isPng, isWebp);
      }

      final dir = await getTemporaryDirectory();
      final targetPath = p.join(dir.path, '${_uuid.v4()}_compressed.jpg');

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 75,
        minWidth: 1920,
        minHeight: 1920,
        format: CompressFormat.jpeg,
        keepExif: true,
      );

      if (result == null) return file;
      return File(result.path);
    } catch (e) {
      debugPrint('Compression error: $e');
      return file;
    }
  }

  Future<File> _compressPreservingAlpha(
    File file,
    bool isPng,
    bool isWebp,
  ) async {
    try {
      final dir = await getTemporaryDirectory();
      final ext = isPng ? 'png' : 'webp';
      final targetPath = p.join(dir.path, '${_uuid.v4()}_$ext');

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: isPng ? 100 : 85,
        minWidth: 1920,
        minHeight: 1920,
        format: isPng ? CompressFormat.png : CompressFormat.webp,
        keepExif: true,
      );

      if (result == null) return file;
      return File(result.path);
    } catch (e) {
      debugPrint('Alpha compression error: $e');
      return file;
    }
  }

  // ═══════════════════════════════════════════════
  // 📥 جلب الصور
  // ═══════════════════════════════════════════════
  Future<List<PhotoModel>> getPhotos({
    String? category,
    String? searchQuery,
    String sortBy = 'newest',
    int limit = 100,
  }) async {
    // ✅ استخدام RPC — يتجاوز مشاكل PostgREST cache
    final response = await _supabase.rpc(
      'get_photos_with_owners',
      params: {
        'p_category': category,
        'p_search': searchQuery,
        'p_sort_by': sortBy,
        'p_limit': limit,
      },
    );

    return (response as List).map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      // نُعيد شكل JSON المشابه للـ JOIN السابق
      final ownerData = map.remove('owner_data');
      return PhotoModel.fromJson({
        ...map,
        'profiles': ownerData,
      });
    }).toList();
  }


  Future<List<PhotoModel>> getUserPhotos(String userId) async {
    final response = await _supabase
        .from('photos')
        .select(
            '*, profiles:user_id(id, username, email, avatar_url, is_admin, active_icon_url, active_icon_expires_at)')
        .eq('user_id', userId)
        .or('is_group_cover.eq.true,group_id.is.null')
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => PhotoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════════════════════════════════
  // 📤 رفع صورة واحدة
  // ═══════════════════════════════════════════════
  Future<PhotoModel> uploadPhoto({
    required File file,
    required String title,
    required String category,
    required double price,
    required String format,
    VoidCallback? onProgress,
  }) async {
    final results = await uploadPhotoGroup(
      files: [file],
      formats: [format],
      title: title,
      category: category,
      price: price,
    );
    return results.first;
  }

  // ═══════════════════════════════════════════════
  // 📤 رفع مجموعة صور
  // ═══════════════════════════════════════════════
  Future<List<PhotoModel>> uploadPhotoGroup({
    required List<File> files,
    required List<String> formats,
    required String title,
    required String category,
    required double price,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final results = <PhotoModel>[];
    final groupId = files.length > 1 ? _uuid.v4() : null;

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final rawFormat = formats[i].toLowerCase();
      final finalFormat = rawFormat == 'jpeg' ? 'jpg' : rawFormat;
      final isCover = i == 0;

      final fileName = '${_uuid.v4()}.$finalFormat';
      final filePath = '$userId/$fileName';

      final compressed = await _compressImage(file, finalFormat);
      final contentType = _contentTypeFor(finalFormat);

      await _supabase.storage.from('photos').upload(
            filePath,
            compressed,
            fileOptions: FileOptions(
              upsert: false,
              cacheControl: '3600',
              contentType: contentType,
            ),
          );

      final imageUrl =
          _supabase.storage.from('photos').getPublicUrl(filePath);

      final response = await _supabase
          .from('photos')
          .insert({
            'user_id': userId,
            'title': title.trim(),
            'category': category,
            'price': price,
            'image_url': imageUrl,
            'format': finalFormat,
            'group_id': groupId,
            'group_order': i,
            'is_group_cover': isCover,
          })
          .select(
              '*, profiles:user_id(id, username, email, avatar_url, is_admin, active_icon_url, active_icon_expires_at)')
          .single();

      results.add(PhotoModel.fromJson(response));
    }

    return results;
  }

  String _contentTypeFor(String format) {
    switch (format) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  // ═══════════════════════════════════════════════
  // 📥 جلب صور مجموعة
  // ═══════════════════════════════════════════════
  Future<List<PhotoModel>> getGroupPhotos(String groupId) async {
    final response = await _supabase
        .from('photos')
        .select(
            '*, profiles:user_id(id, username, email, avatar_url, is_admin, active_icon_url, active_icon_expires_at)')
        .eq('group_id', groupId)
        .order('group_order', ascending: true);

    return (response as List)
        .map((e) => PhotoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════════════════════════════════
  // ✏️ تعديل صورة
  // ═══════════════════════════════════════════════
  Future<PhotoModel> updatePhoto({
    required String photoId,
    String? title,
    String? category,
    double? price,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title.trim();
    if (category != null) updates['category'] = category;
    if (price != null) updates['price'] = price;

    final response = await _supabase
        .from('photos')
        .update(updates)
        .eq('id', photoId)
        .select(
            '*, profiles:user_id(id, username, email, avatar_url, is_admin, active_icon_url, active_icon_expires_at)')
        .single();

    return PhotoModel.fromJson(response);
  }

  // ═══════════════════════════════════════════════
  // 🛒 الشراء
  // ═══════════════════════════════════════════════
  Future<void> purchasePhoto(String photoId) async {
    await _supabase.rpc('purchase_photo', params: {'p_photo_id': photoId});
  }

  Future<void> purchasePhotoGroup(String groupId) async {
    await _supabase.rpc(
      'purchase_photo_group',
      params: {'p_group_id': groupId},
    );
  }

  Future<bool> hasPurchased(String photoId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final result = await _supabase
          .from('purchases')
          .select('id')
          .eq('user_id', userId)
          .eq('photo_id', photoId)
          .maybeSingle();
      return result != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPurchasedGroup(String groupId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final result = await _supabase
          .from('purchases')
          .select('photo_id, photos:photo_id(group_id)')
          .eq('user_id', userId);

      return (result as List).any((row) {
        final photo = row['photos'];
        return photo != null && photo['group_id'] == groupId;
      });
    } catch (_) {
      return false;
    }
  }

  Future<List<PhotoModel>> getMyPurchases() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final response = await _supabase
          .from('purchases')
          .select(
              'photo_id, photos:photo_id(*, profiles:user_id(id, username, email, avatar_url, is_admin))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .where((e) => e['photos'] != null)
          .map((e) => PhotoModel.fromJson(e['photos'] as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════
  // 🗑️ حذف
  // ═══════════════════════════════════════════════
  Future<void> deletePhoto({
    required String photoId,
    required String imageUrl,
  }) async {
    try {
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      final photosIndex = segments.indexOf('photos');
      final filePath = segments.sublist(photosIndex + 1).join('/');
      await _supabase.storage.from('photos').remove([filePath]);
    } catch (e) {
      debugPrint('Storage delete error: $e');
    }

    String? groupId;
    try {
      final row = await _supabase
          .from('photos')
          .select('group_id')
          .eq('id', photoId)
          .maybeSingle();
      groupId = row?['group_id'] as String?;
    } catch (_) {}

    if (groupId != null && groupId.isNotEmpty) {
      await _supabase.from('photos').delete().eq('group_id', groupId);
    } else {
      await _supabase.from('photos').delete().eq('id', photoId);
    }
  }
}

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
  // 🎨 ضغط الصورة (يحافظ على الشفافية في PNG)
  // ═══════════════════════════════════════════════
  Future<File> _compressImage(File file, String format) async {
    try {
      final lowerFormat = format.toLowerCase();
      final isPng = lowerFormat == 'png';
      final isWebp = lowerFormat == 'webp';

      // ⚠️ PNG و WebP: نحافظ على الشفافية
      if (isPng || isWebp) {
        return await _compressPreservingAlpha(file, isPng, isWebp);
      }

      // JPG/JPEG: ضغط عادي (لا يوجد شفافية أصلاً)
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

      final compressed = File(result.path);
      debugPrint(
        '📸 JPG: ${(await file.length() / 1024 / 1024).toStringAsFixed(2)}MB → '
        '${(await compressed.length() / 1024 / 1024).toStringAsFixed(2)}MB',
      );
      return compressed;
    } catch (e) {
      debugPrint('Compression error: $e');
      return file;
    }
  }

  // ─── ضغط PNG/WebP مع الحفاظ على الشفافية ───
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
        // PNG: نستخدم quality: 100 للحفاظ على الجودة والشفافية
        quality: isPng ? 100 : 85,
        minWidth: 1920,
        minHeight: 1920,
        format: isPng ? CompressFormat.png : CompressFormat.webp,
        keepExif: true,
      );

      if (result == null) return file;

      final compressed = File(result.path);
      debugPrint(
        '📸 $ext: ${(await file.length() / 1024).toStringAsFixed(0)}KB → '
        '${(await compressed.length() / 1024).toStringAsFixed(0)}KB (شفاف ✅)',
      );
      return compressed;
    } catch (e) {
      debugPrint('Alpha compression error: $e');
      return file; // إرجاع الأصل عند الفشل
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
    dynamic query = _supabase
        .from('photos')
        .select(
          '*, profiles:user_id(id, username, email, avatar_url, is_admin)',
        );

    if (category != null && category.isNotEmpty && category != 'all') {
      query = query.eq('category', category);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('title', '%$searchQuery%');
    }

    switch (sortBy) {
      case 'oldest':
        query = query.order('created_at', ascending: true);
        break;
      case 'price_high':
        query = query.order('price', ascending: false);
        break;
      case 'price_low':
        query = query.order('price', ascending: true);
        break;
      case 'newest':
      default:
        query = query.order('created_at', ascending: false);
    }

    final response = await query.limit(limit);

    return (response as List)
        .map((e) => PhotoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PhotoModel>> getUserPhotos(String userId) async {
    final response = await _supabase
        .from('photos')
        .select(
          '*, profiles:user_id(id, username, email, avatar_url, is_admin)',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => PhotoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════════════════════════════════
  // 📤 رفع صورة جديدة (يستخدم الملف المُعطى مباشرة)
  // ═══════════════════════════════════════════════
  Future<PhotoModel> uploadPhoto({
    required File file,
    required String title,
    required String category,
    required double price,
    required String format,
    VoidCallback? onProgress,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final lowerFormat = format.toLowerCase();
    final finalFormat = lowerFormat == 'jpeg' ? 'jpg' : lowerFormat;

    // الحفاظ على امتداد الملف الأصلي (PNG يبقى PNG)
    final fileName = '${_uuid.v4()}.$finalFormat';
    final filePath = '$userId/$fileName';

    // ضغط مع الحفاظ على الشفافية
    final compressedFile = await _compressImage(file, finalFormat);

    // إعداد Content-Type المناسب
    final contentType = _contentTypeFor(finalFormat);

    await _supabase.storage.from('photos').upload(
          filePath,
          compressedFile,
          fileOptions: FileOptions(
            upsert: false,
            cacheControl: '3600',
            contentType: contentType,
          ),
        );

    final imageUrl = _supabase.storage.from('photos').getPublicUrl(filePath);

    final response = await _supabase
        .from('photos')
        .insert({
          'user_id': userId,
          'title': title.trim(),
          'category': category,
          'price': price,
          'image_url': imageUrl,
          'format': finalFormat,
        })
        .select('*, profiles:user_id(id, username, email, avatar_url, is_admin)')
        .single();

    return PhotoModel.fromJson(response);
  }

  String _contentTypeFor(String format) {
    switch (format) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
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
        .select('*, profiles:user_id(id, username, email, avatar_url, is_admin)')
        .single();

    return PhotoModel.fromJson(response);
  }

  // ═══════════════════════════════════════════════
  // 🛒 شراء صورة
  // ═══════════════════════════════════════════════
  Future<void> purchasePhoto(String photoId) async {
    await _supabase.rpc(
      'purchase_photo',
      params: {'p_photo_id': photoId},
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
    } catch (e) {
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
            'photo_id, '
            'photos:photo_id(*, profiles:user_id(id, username, email, avatar_url, is_admin))',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .where((e) => e['photos'] != null)
          .map((e) => PhotoModel.fromJson(e['photos'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════
  // 🗑️ حذف صورة
  // ═══════════════════════════════════════════════
  Future<void> deletePhoto({
    required String photoId,
    required String imageUrl,
  }) async {
    final uri = Uri.parse(imageUrl);
    final segments = uri.pathSegments;
    final photosIndex = segments.indexOf('photos');
    final filePath = segments.sublist(photosIndex + 1).join('/');

    try {
      await _supabase.storage.from('photos').remove([filePath]);
    } catch (e) {
      debugPrint('Storage delete error: $e');
    }

    await _supabase.from('photos').delete().eq('id', photoId);
  }
}

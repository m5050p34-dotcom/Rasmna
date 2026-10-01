import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/icon_model.dart';

class IconStoreService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // ═══════════════════════════════════════════════
  // 📦 جلب الأيقونات المتاحة في المتجر
  // ═══════════════════════════════════════════════
  Future<List<IconModel>> getAllIcons({bool onlyActive = true}) async {
    var query = _supabase.from('icons').select();
    if (onlyActive) query = query.eq('is_active', true);

    final response = await query
        .order('display_order', ascending: true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => IconModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════════════════════════════════
  // 🛒 شراء أيقونة (عبر RPC آمن)
  // ═══════════════════════════════════════════════
  Future<PurchaseIconResult> purchaseIcon(String iconId) async {
    try {
      final response = await _supabase.rpc(
        'purchase_icon',
        params: {'p_icon_id': iconId},
      );

      if (response is Map<String, dynamic>) {
        return PurchaseIconResult.fromJson(response);
      } else if (response is Map) {
        return PurchaseIconResult.fromJson(
          Map<String, dynamic>.from(response),
        );
      }
      throw Exception('استجابة غير متوقعة من الخادم');
    } on PostgrestException catch (e) {
      final msg = e.message;
      if (msg.contains('Insufficient points')) {
        throw Exception('رصيدك غير كافٍ لشراء هذه الأيقونة');
      }
      if (msg.contains('already own')) {
        throw Exception('أنت تملك هذه الأيقونة بالفعل');
      }
      if (msg.contains('not available')) {
        throw Exception('هذه الأيقونة غير متاحة حالياً');
      }
      if (msg.contains('not found')) {
        throw Exception('الأيقونة غير موجودة');
      }
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════
  // 📜 جلب سجل مشتريات المستخدم
  // ═══════════════════════════════════════════════
  Future<List<UserIconModel>> getUserIconHistory(String userId) async {
    final response = await _supabase
        .from('user_icons')
        .select('*, icons(*)')
        .eq('user_id', userId)
        .order('purchased_at', ascending: false);

    return (response as List)
        .map((e) => UserIconModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════════════════════════════════
  // ✏️ إدارة الأدمن: إنشاء أيقونة
  // ═══════════════════════════════════════════════
  Future<IconModel> createIcon({
    required String name,
    String? description,
    required File imageFile,
    required int price,
    int durationDays = 30,
    int displayOrder = 0,
  }) async {
    // 1) رفع الصورة
    final imageUrl = await _uploadIconImage(imageFile);

    // 2) إدراج السجل
    final response = await _supabase
        .from('icons')
        .insert({
          'name': name,
          'description': description,
          'image_url': imageUrl,
          'price': price,
          'duration_days': durationDays,
          'display_order': displayOrder,
          'is_active': true,
          'created_by': _supabase.auth.currentUser?.id,
        })
        .select()
        .single();

    return IconModel.fromJson(response);
  }

  // ═══════════════════════════════════════════════
  // ✏️ إدارة الأدمن: تحديث أيقونة
  // ═══════════════════════════════════════════════
  Future<void> updateIcon({
    required String iconId,
    String? name,
    String? description,
    int? price,
    int? durationDays,
    int? displayOrder,
    bool? isActive,
    File? newImageFile,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (price != null) updates['price'] = price;
    if (durationDays != null) updates['duration_days'] = durationDays;
    if (displayOrder != null) updates['display_order'] = displayOrder;
    if (isActive != null) updates['is_active'] = isActive;

    if (newImageFile != null) {
      updates['image_url'] = await _uploadIconImage(newImageFile);
    }

    if (updates.isEmpty) return;

    await _supabase.from('icons').update(updates).eq('id', iconId);
  }

  // ═══════════════════════════════════════════════
  // 🗑️ إدارة الأدمن: حذف أيقونة
  // ═══════════════════════════════════════════════
  Future<void> deleteIcon(String iconId) async {
    // حذف السجل (سيحذف الملف من Storage تلقائياً لو أردت،
    // لكن لتبسيط الأمر سنحذف السجل فقط)
    await _supabase.from('icons').delete().eq('id', iconId);
  }

  // ═══════════════════════════════════════════════
  // 📤 رفع صورة الأيقونة إلى Storage
  // ═══════════════════════════════════════════════
  Future<String> _uploadIconImage(File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    final fileName = 'icon_${_uuid.v4()}.$ext';
    final path = 'library/$fileName';

    await _supabase.storage.from('icons').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: false),
        );

    return _supabase.storage.from('icons').getPublicUrl(path);
  }

  // ═══════════════════════════════════════════════
  // 🧹 تنظيف الأيقونات المنتهية (اختياري)
  // ═══════════════════════════════════════════════
  Future<int> cleanupExpiredIcons() async {
    final response =
        await _supabase.rpc('cleanup_expired_icons');
    return (response as num?)?.toInt() ?? 0;
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/photo_category_model.dart';

class CategoriesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PhotoCategoryModel>> getCategories({bool onlyEnabled = false}) async {
    var query = _supabase.from('photo_categories').select();
    if (onlyEnabled) query = query.eq('enabled', true);
    final response = await query.order('display_order', ascending: true);
    return (response as List)
        .map((e) => PhotoCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PhotoCategoryModel> createCategory({
    required String key,
    required String labelAr,
    required String labelEn,
    String? iconName,
    int displayOrder = 99,
  }) async {
    final response = await _supabase
        .from('photo_categories')
        .insert({
          'key': key.toLowerCase().replaceAll(' ', '_'),
          'label_ar': labelAr,
          'label_en': labelEn,
          'icon_name': iconName,
          'display_order': displayOrder,
        })
        .select()
        .single();
    return PhotoCategoryModel.fromJson(response);
  }

  Future<void> updateCategory(String id, Map<String, dynamic> updates) async {
    await _supabase.from('photo_categories').update(updates).eq('id', id);
  }

  Future<void> deleteCategory(String id) async {
    await _supabase.from('photo_categories').delete().eq('id', id);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sort_option_model.dart';

class SortService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<SortOptionModel>> getAllSortOptions({bool onlyEnabled = false}) async {
    var query = _supabase.from('sort_options').select();
    if (onlyEnabled) query = query.eq('enabled', true);
    final response = await query.order('display_order');
    return (response as List)
        .map((e) => SortOptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SortOptionModel> createSortOption({
    required String key,
    required String labelAr,
    required String labelEn,
    int displayOrder = 99,
  }) async {
    final response = await _supabase
        .from('sort_options')
        .insert({
          'key': key,
          'label_ar': labelAr,
          'label_en': labelEn,
          'display_order': displayOrder,
        })
        .select()
        .single();
    return SortOptionModel.fromJson(response);
  }

  Future<void> updateSortOption(
    String id,
    Map<String, dynamic> updates,
  ) async {
    await _supabase.from('sort_options').update(updates).eq('id', id);
  }

  Future<void> deleteSortOption(String id) async {
    await _supabase.from('sort_options').delete().eq('id', id);
  }

  Future<void> setAsDefault(String id) async {
    await _supabase
        .from('sort_options')
        .update({'is_default': false}).neq('id', id);
    await _supabase
        .from('sort_options')
        .update({'is_default': true}).eq('id', id);
  }
}

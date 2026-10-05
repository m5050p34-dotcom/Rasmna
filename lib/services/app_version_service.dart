import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_version_model.dart';

class AppVersionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// جلب أحدث إصدار فعال من Supabase
  Future<AppVersionModel?> getLatestVersion() async {
    try {
      final response = await _supabase
          .from('app_versions')
          .select()
          .eq('is_active', true)
          .order('version_code', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return AppVersionModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// جلب جميع الإصدارات (للأدمن)
  Future<List<AppVersionModel>> getAllVersions() async {
    final response = await _supabase
        .from('app_versions')
        .select()
        .order('version_code', ascending: false);

    return (response as List)
        .map((e) => AppVersionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// الحصول على إصدار التطبيق الحالي
  Future<({String name, int code})> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    final code = int.tryParse(info.buildNumber) ?? 0;
    return (name: info.version, code: code);
  }

  /// التحقق من وجود تحديث
  /// يعيد: null إذا لا يوجد تحديث، أو AppVersionModel إذا وُجد
  Future<AppVersionModel?> checkForUpdate() async {
    try {
      final current = await getCurrentVersion();
      final latest = await getLatestVersion();

      if (latest == null) return null;
      if (latest.versionCode <= current.code) return null;

      return latest;
    } catch (e) {
      return null;
    }
  }

  /// إنشاء إصدار جديد (للأدمن)
  Future<void> createVersion(AppVersionModel version) async {
    await _supabase.from('app_versions').insert(version.toJson());
  }

  /// تحديث إصدار (للأدمن)
  Future<void> updateVersion(String id, Map<String, dynamic> updates) async {
    await _supabase.from('app_versions').update(updates).eq('id', id);
  }

  /// حذف إصدار (للأدمن)
  Future<void> deleteVersion(String id) async {
    await _supabase.from('app_versions').delete().eq('id', id);
  }
}

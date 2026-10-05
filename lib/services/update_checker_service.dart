import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_version_model.dart';

class UpdateCheckerService {
  static const _lastSeenKey = 'last_seen_version_code';

  final _supabase = Supabase.instance.client;

  /// يفحص إن كان يجب عرض الديالوج
  /// يعيد: AppVersionModel إذا يجب العرض، null إذا لا
  Future<AppVersionModel?> shouldShowUpdate() async {
    try {
      // 1) نسخة التطبيق الحالية
      final info = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(info.buildNumber) ?? 0;

      // 2) أحدث إصدار من Supabase
      final response = await _supabase
          .from('app_versions')
          .select()
          .eq('is_active', true)
          .order('version_code', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      final latest = AppVersionModel.fromJson(response);

      // 3) إذا كان أحدث من المثبّت
      if (latest.versionCode <= currentCode) return null;

      // 4) إذا إلزامي → اعرضه دائماً
      if (latest.isMandatory) return latest;

      // 5) إذا اختياري → اعرضه مرة واحدة لكل إصدار
      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getInt(_lastSeenKey) ?? 0;

      if (latest.versionCode > lastSeen) {
        return latest;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// يُسجّل أن المستخدم رأى الإصدار (لعدم تكرار الديالوج)
  Future<void> markAsSeen(int versionCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSeenKey, versionCode);
    } catch (_) {}
  }
}

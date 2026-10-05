import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_version_model.dart';

class UpdateCheckerService {
  static const _lastSeenKey = 'last_seen_version_code';

  final _supabase = Supabase.instance.client;

  Future<({int current, int? latest, bool showDialog, String reason})>
      debugInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(info.buildNumber) ?? 0;

      final response = await _supabase
          .from('app_versions')
          .select()
          .eq('is_active', true)
          .order('version_code', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return (
          current: currentCode,
          latest: null,
          showDialog: false,
          reason: 'no_active_versions_in_db',
        );
      }

      final latest = AppVersionModel.fromJson(response);
      debugPrint('📱 Current: $currentCode | Latest: ${latest.versionCode}');

      if (latest.versionCode <= currentCode) {
        return (
          current: currentCode,
          latest: latest.versionCode,
          showDialog: false,
          reason: 'up_to_date',
        );
      }

      if (latest.isMandatory) {
        return (
          current: currentCode,
          latest: latest.versionCode,
          showDialog: true,
          reason: 'mandatory',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getInt(_lastSeenKey) ?? 0;

      if (latest.versionCode > lastSeen) {
        return (
          current: currentCode,
          latest: latest.versionCode,
          showDialog: true,
          reason: 'optional_new',
        );
      }

      return (
        current: currentCode,
        latest: latest.versionCode,
        showDialog: false,
        reason: 'already_seen',
      );
    } catch (e) {
      debugPrint('❌ UpdateChecker error: $e');
      return (
        current: 0,
        latest: null,
        showDialog: false,
        reason: 'error: $e',
      );
    }
  }

  Future<AppVersionModel?> shouldShowUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(info.buildNumber) ?? 0;

      debugPrint('═══════════════════════════════════');
      debugPrint('🔍 UPDATE CHECK');
      debugPrint('   App version name: ${info.version}');
      debugPrint('   App build number: ${info.buildNumber}');
      debugPrint('   Parsed versionCode: $currentCode');
      debugPrint('═══════════════════════════════════');

      final response = await _supabase
          .from('app_versions')
          .select()
          .eq('is_active', true)
          .order('version_code', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ No active versions in DB');
        return null;
      }

      final latest = AppVersionModel.fromJson(response);
      debugPrint('📦 Latest in DB:');
      debugPrint('   name: ${latest.versionName}');
      debugPrint('   code: ${latest.versionCode}');
      debugPrint('   mandatory: ${latest.isMandatory}');
      debugPrint('   active: ${latest.isActive}');

      if (latest.versionCode <= currentCode) {
        debugPrint('✅ Up to date (latest <= current)');
        return null;
      }

      debugPrint('🎉 Update available! Showing dialog...');

      if (latest.isMandatory) {
        debugPrint('   Reason: MANDATORY');
        return latest;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getInt(_lastSeenKey) ?? 0;
      debugPrint('   Last seen: $lastSeen');

      if (latest.versionCode > lastSeen) {
        debugPrint('   Reason: OPTIONAL (first time)');
        return latest;
      }

      debugPrint('   Reason: already seen');
      return null;
    } catch (e, stack) {
      debugPrint('❌ Update check error: $e');
      debugPrint('$stack');
      return null;
    }
  }

  Future<void> markAsSeen(int versionCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSeenKey, versionCode);
      debugPrint('✅ Marked version $versionCode as seen');
    } catch (_) {}
  }

  /// إعادة تعيين (للاختبار)
  Future<void> resetSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSeenKey);
    debugPrint('🔄 Reset seen versions');
  }
}

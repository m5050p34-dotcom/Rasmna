import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_version_model.dart';

/// خدمة فحص التحديثات
///
/// تقارن إصدار التطبيق المثبّت مع أحدث إصدار في قاعدة البيانات،
/// وتقرر ما إذا كان يجب عرض ديالوج التحديث.
class UpdateCheckerService {
  static const String _lastSeenKey = 'last_seen_version_code';

  final SupabaseClient _supabase = Supabase.instance.client;

  /// نتيجة فحص التحديث
  Future<UpdateCheckResult> check() async {
    try {
      // 1) الإصدار الحالي
      final info = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(info.buildNumber) ?? 0;

      // 2) أحدث إصدار من DB
      final response = await _supabase
          .from('app_versions')
          .select()
          .eq('is_active', true)
          .order('version_code', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return UpdateCheckResult(
          currentCode: currentCode,
          latestCode: null,
          version: null,
          shouldShow: false,
          reason: UpdateCheckReason.noActiveVersions,
        );
      }

      final latest = AppVersionModel.fromJson(response);

      // 3) هل التطبيق محدّث بالفعل؟
      if (latest.versionCode <= currentCode) {
        return UpdateCheckResult(
          currentCode: currentCode,
          latestCode: latest.versionCode,
          version: null,
          shouldShow: false,
          reason: UpdateCheckReason.upToDate,
        );
      }

      // 4) إذا إلزامي → يظهر دائماً
      if (latest.isMandatory) {
        return UpdateCheckResult(
          currentCode: currentCode,
          latestCode: latest.versionCode,
          version: latest,
          shouldShow: true,
          reason: UpdateCheckReason.mandatory,
        );
      }

      // 5) إذا اختياري → يظهر مرة واحدة لكل إصدار
      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getInt(_lastSeenKey) ?? 0;

      if (latest.versionCode > lastSeen) {
        return UpdateCheckResult(
          currentCode: currentCode,
          latestCode: latest.versionCode,
          version: latest,
          shouldShow: true,
          reason: UpdateCheckReason.optionalNew,
        );
      }

      return UpdateCheckResult(
        currentCode: currentCode,
        latestCode: latest.versionCode,
        version: null,
        shouldShow: false,
        reason: UpdateCheckReason.alreadySeen,
      );
    } catch (e, stack) {
      debugPrint('❌ UpdateCheck error: $e');
      if (kDebugMode) debugPrint('$stack');

      return UpdateCheckResult(
        currentCode: 0,
        latestCode: null,
        version: null,
        shouldShow: false,
        reason: UpdateCheckReason.error,
      );
    }
  }

  /// اختصار: يُعيد الإصدار إذا يجب العرض، أو null
  Future<AppVersionModel?> shouldShowUpdate() async {
    final result = await check();
    return result.shouldShow ? result.version : null;
  }

  /// تسجيل أن المستخدم رأى الإصدار (لمنع تكرار الاختياري)
  Future<void> markAsSeen(int versionCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSeenKey, versionCode);
    } catch (e) {
      debugPrint('⚠️ markAsSeen error: $e');
    }
  }

  /// إعادة تعيين الذاكرة (للاختبار فقط)
  Future<void> resetSeenVersions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSeenKey);
  }
}

// ═══════════════════════════════════════════════════════════
// نتيجة فحص التحديث
// ═══════════════════════════════════════════════════════════
class UpdateCheckResult {
  final int currentCode;
  final int? latestCode;
  final AppVersionModel? version;
  final bool shouldShow;
  final UpdateCheckReason reason;

  const UpdateCheckResult({
    required this.currentCode,
    required this.latestCode,
    required this.version,
    required this.shouldShow,
    required this.reason,
  });
}

enum UpdateCheckReason {
  /// لا يوجد إصدار نشط في DB
  noActiveVersions,

  /// التطبيق محدّث بالفعل
  upToDate,

  /// تحديث إلزامي متوفر
  mandatory,

  /// تحديث اختياري جديد (أول مرة)
  optionalNew,

  /// رأى المستخدم الديالوج سابقاً
  alreadySeen,

  /// حدث خطأ
  error,
}

extension UpdateCheckReasonLabel on UpdateCheckReason {
  String get label {
    switch (this) {
      case UpdateCheckReason.noActiveVersions:
        return 'no_active_versions_in_db';
      case UpdateCheckReason.upToDate:
        return 'up_to_date';
      case UpdateCheckReason.mandatory:
        return 'mandatory';
      case UpdateCheckReason.optionalNew:
        return 'optional_new';
      case UpdateCheckReason.alreadySeen:
        return 'already_seen';
      case UpdateCheckReason.error:
        return 'error';
    }
  }

  String get arabicLabel {
    switch (this) {
      case UpdateCheckReason.noActiveVersions:
        return 'لا يوجد إصدار نشط';
      case UpdateCheckReason.upToDate:
        return 'محدّث بالفعل';
      case UpdateCheckReason.mandatory:
        return 'تحديث إلزامي';
      case UpdateCheckReason.optionalNew:
        return 'تحديث اختياري جديد';
      case UpdateCheckReason.alreadySeen:
        return 'شوهد سابقاً';
      case UpdateCheckReason.error:
        return 'خطأ';
    }
  }
}

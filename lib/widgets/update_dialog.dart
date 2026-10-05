import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_version_model.dart';
import '../utils/app_theme.dart';

/// ديالوج عرض التحديثات
///
/// - إلزامي: لا يمكن إغلاقه، فقط زر "تحديث الآن"
/// - اختياري: يمكن إغلاقه بزر "لاحقاً"
class UpdateDialog extends StatelessWidget {
  final AppVersionModel version;

  const UpdateDialog({super.key, required this.version});

  static Future<void> show(
    BuildContext context,
    AppVersionModel version,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: !version.isMandatory,
      builder: (_) => UpdateDialog(version: version),
    );
  }

  Future<void> _openDownload(BuildContext context) async {
    final url = Uri.parse(version.downloadUrl);
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showError(context);
      }
    } catch (e) {
      if (context.mounted) _showError(context);
    }
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تعذّر فتح رابط التحميل'),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMandatory = version.isMandatory;
    final features = _parseFeatures();
    final accentColor = isMandatory ? AppTheme.error : AppTheme.primary;

    return PopScope(
      canPop: !isMandatory,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ═══ الرأس ═══
              _buildHeader(isMandatory, accentColor),

              // ═══ المحتوى ═══
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isMandatory) _buildMandatoryWarning(),
                      if (features.isNotEmpty) ...[
                        const Text(
                          'ما الجديد:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...features.map((f) => _buildFeatureRow(f)),
                      ] else
                        const Text(
                          'تحسينات وإصلاحات متنوعة',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ═══ الأزرار ═══
              _buildActions(context, isMandatory, accentColor),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // الرأس
  // ═══════════════════════════════════════════════
  Widget _buildHeader(bool isMandatory, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMandatory
              ? [AppTheme.error, AppTheme.error.withValues(alpha: 0.75)]
              : [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMandatory
                  ? Icons.warning_amber_rounded
                  : Icons.system_update,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMandatory ? 'تحديث إلزامي' : 'يتوفر تحديث',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'الإصدار ${version.versionName}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // تنبيه الإلزامي
  // ═══════════════════════════════════════════════
  Widget _buildMandatoryWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.error, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'يجب التحديث للمتابعة',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // صف ميزة
  // ═══════════════════════════════════════════════
  Widget _buildFeatureRow(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // الأزرار
  // ═══════════════════════════════════════════════
  Widget _buildActions(
    BuildContext context,
    bool isMandatory,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (!isMandatory) ...[
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: Colors.grey.shade600,
                ),
                child: const Text(
                  'لاحقاً',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: isMandatory ? 1 : 2,
            child: ElevatedButton.icon(
              onPressed: () => _openDownload(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.download, size: 18),
              label: const Text(
                'تحديث الآن',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // تحليل الميزات
  // ═══════════════════════════════════════════════
  List<String> _parseFeatures() {
    return version.changelog
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }
}

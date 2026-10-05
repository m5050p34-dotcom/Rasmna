import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_version_model.dart';
import '../utils/app_theme.dart';

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

  Future<void> _openDownload() async {
    final url = Uri.parse(version.downloadUrl);
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        debugPrint('Failed to launch URL: $url');
      }
    } catch (e) {
      debugPrint('URL launch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMandatory = version.isMandatory;
    final features = version.changelog
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    return PopScope(
      canPop: !isMandatory,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isMandatory ? AppTheme.error : AppTheme.primary)
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMandatory ? Icons.warning_amber_rounded : Icons.system_update,
                color: isMandatory ? AppTheme.error : AppTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMandatory ? 'تحديث إلزامي' : 'يتوفر تحديث',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isMandatory ? AppTheme.error : null,
                    ),
                  ),
                  Text(
                    'الإصدار ${version.versionName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).disabledColor,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMandatory)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppTheme.error, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'يجب التحديث للمتابعة',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const Text(
                'ما الجديد:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              ...features.map((feature) => Padding(
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
                            feature.trim(),
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          if (!isMandatory)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لاحقاً'),
            ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isMandatory ? AppTheme.error : AppTheme.primary,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
            ),
            onPressed: _openDownload,
            icon: const Icon(Icons.download, size: 18),
            label: const Text(
              'تحديث الآن',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

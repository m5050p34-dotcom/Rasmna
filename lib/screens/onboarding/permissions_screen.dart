import 'package:flutter/material.dart';

import '../../services/permissions_service.dart';
import '../../utils/app_theme.dart';

class PermissionsScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const PermissionsScreen({super.key, required this.onComplete});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  int _currentStep = 0;
  bool _isProcessing = false;
  final Map<String, bool> _results = {};

  // ═══════════════════════════════════════════════
  // الأذونات المطلوبة
  // ═══════════════════════════════════════════════
  final List<_PermissionItem> _permissions = [
    _PermissionItem(
      key: 'notifications',
      icon: Icons.notifications_active,
      color: AppTheme.error,
      title: 'الإشعارات',
      subtitle: 'لتصلك تنبيهات عند بيع صورك أو متابعتك',
      action: () => PermissionsService.requestNotificationPermission(),
    ),
    _PermissionItem(
      key: 'camera',
      icon: Icons.camera_alt,
      color: AppTheme.primary,
      title: 'الكاميرا',
      subtitle: 'لالتقاط صور جديدة ورفعها مباشرة',
      action: () => PermissionsService.requestCameraPermission(),
    ),
    _PermissionItem(
      key: 'storage',
      icon: Icons.photo_library,
      color: AppTheme.success,
      title: 'الوصول للصور',
      subtitle: 'لحفظ الصور التي تشتريها في معرض هاتفك',
      action: () => PermissionsService.requestStoragePermission(),
    ),
  ];

  Future<void> _requestNext() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final item = _permissions[_currentStep];
      final granted = await item.action();
      _results[item.key] = granted;

      if (!mounted) return;

      if (_currentStep < _permissions.length - 1) {
        setState(() {
          _currentStep++;
          _isProcessing = false;
        });
      } else {
        // انتهت جميع الأذونات
        await _finish();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _finish() async {
    await PermissionsService.markFirstLaunchDone();
    await PermissionsService.markNotificationsAsked();
    if (mounted) {
      widget.onComplete();
    }
  }

  Future<void> _skip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تخطي الأذونات؟'),
        content: const Text(
          'لن تتمكن من الحصول على بعض الميزات مثل الإشعارات وحفظ الصور.\n\n'
          'يمكنك تفعيلها لاحقاً من إعدادات التطبيق.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('رجوع'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تخطي'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _permissions[_currentStep];
    final progress = (_currentStep + 1) / _permissions.length;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // ═══════════════════════════════════
                // شريط التقدم
                // ═══════════════════════════════════
                Row(
                  children: [
                    Text(
                      '${_currentStep + 1} / ${_permissions.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor:
                              Theme.of(context).disabledColor.withValues(alpha: 0.2),
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // ═══════════════════════════════════
                // أيقونة كبيرة
                // ═══════════════════════════════════
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        item.color.withValues(alpha: 0.3),
                        item.color.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: item.color.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    item.icon,
                    size: 70,
                    color: item.color,
                  ),
                ),

                const SizedBox(height: 40),

                // ═══════════════════════════════════
                // العنوان
                // ═══════════════════════════════════
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // ═══════════════════════════════════
                // الوصف
                // ═══════════════════════════════════
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    item.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ═══════════════════════════════════
                // ملاحظة صغيرة
                // ═══════════════════════════════════
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppTheme.warning, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ستظهر نافذة النظام للسماح — اضغط "السماح"',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ═══════════════════════════════════
                // زر المتابعة
                // ═══════════════════════════════════
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _requestNext,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _currentStep == _permissions.length - 1
                                ? Icons.check_circle
                                : Icons.arrow_forward,
                            size: 22,
                          ),
                    label: Text(
                      _isProcessing
                          ? 'جارٍ الطلب...'
                          : _currentStep == _permissions.length - 1
                              ? 'ابدأ الاستخدام'
                              : 'السماح والمتابعة',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ═══════════════════════════════════
                // زر التخطي
                // ═══════════════════════════════════
                TextButton(
                  onPressed: _isProcessing ? null : _skip,
                  child: Text(
                    'تخطي',
                    style: TextStyle(
                      color: Theme.of(context).disabledColor,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// نموذج إذن
// ═══════════════════════════════════════════════
class _PermissionItem {
  final String key;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Future<bool> Function() action;

  _PermissionItem({
    required this.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.action,
  });
}

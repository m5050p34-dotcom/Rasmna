import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/notifications_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() =>
      _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String _target = 'all';
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════
  // نافذة التأكيد (دالة منفصلة - لا تحتوي على await)
  // ═══════════════════════════════════════════════
  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الإرسال'),
        content: Text(
          'سيتم إرسال الإشعار إلى: ${_targetLabel()}\n\n'
          'العنوان: ${_titleController.text.trim()}\n\n'
          'هل أنت متأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send, size: 18),
            label: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // إرسال الإشعار
  // ═══════════════════════════════════════════════
  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ التقاط المراجع قبل أي await
    final notifProvider = context.read<NotificationsProvider>();
    final messenger = ScaffoldMessenger.of(context);

    // عرض نافذة التأكيد (بدون استخدام context مباشرة)
    final confirmed = await _showConfirmDialog();
    if (confirmed != true) return;

    if (!mounted) return;
    setState(() => _isSending = true);

    try {
      final title = _titleController.text.trim();
      final body = _bodyController.text.trim();

      final count = await notifProvider.adminSend(
        title: title,
        body: body,
        target: _target,
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text('✅ تم إرسال الإشعار إلى $count مستخدم'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 3),
        ),
      );

      _titleController.clear();
      _bodyController.clear();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(Helpers.errorMessage(e)),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _targetLabel() {
    switch (_target) {
      case 'all':
        return 'جميع المستخدمين';
      case 'admins':
        return 'الأدمن فقط';
      case 'users':
        return 'المستخدمين العاديين';
      default:
        return _target;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إرسال إشعار'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ═══════════════════════════════════
              // اختيار المستهدفين
              // ═══════════════════════════════════
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _targetOption(
                      value: 'all',
                      icon: Icons.groups,
                      color: AppTheme.primary,
                      label: 'جميع المستخدمين',
                      subtitle: 'كل الحسابات في التطبيق',
                    ),
                    _targetOption(
                      value: 'users',
                      icon: Icons.people_outline,
                      color: AppTheme.success,
                      label: 'المستخدمون العاديون',
                      subtitle: 'بدون الأدمن',
                    ),
                    _targetOption(
                      value: 'admins',
                      icon: Icons.admin_panel_settings,
                      color: AppTheme.warning,
                      label: 'الأدمن فقط',
                      subtitle: 'المشرفون',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ═══════════════════════════════════
              // عنوان الإشعار
              // ═══════════════════════════════════
              TextFormField(
                controller: _titleController,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'عنوان الإشعار',
                  hintText: 'مثال: عرض خاص 🎉',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'أدخل عنواناً';
                  }
                  if (v.trim().length < 3) {
                    return 'العنوان قصير جداً';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // ═══════════════════════════════════
              // نص الإشعار
              // ═══════════════════════════════════
              TextFormField(
                controller: _bodyController,
                maxLines: 5,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'نص الإشعار',
                  hintText: 'اكتب محتوى الإشعار هنا...',
                  prefixIcon: Icon(Icons.message_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'أدخل نص الإشعار';
                  }
                  if (v.trim().length < 5) {
                    return 'النص قصير جداً';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // ═══════════════════════════════════
              // معاينة الإشعار
              // ═══════════════════════════════════
              if (_titleController.text.isNotEmpty ||
                  _bodyController.text.isNotEmpty) ...[
                const Text(
                  'معاينة الإشعار:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: AppTheme.primary.withValues(alpha: 0.05),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      _titleController.text.isEmpty
                          ? 'عنوان الإشعار'
                          : _titleController.text,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _bodyController.text.isEmpty
                          ? 'نص الإشعار سيظهر هنا...'
                          : _bodyController.text,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ═══════════════════════════════════
              // زر الإرسال
              // ═══════════════════════════════════
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _send,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, size: 22),
                  label: Text(
                    _isSending ? 'جارٍ الإرسال...' : 'إرسال الإشعار',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ─── تنبيه ───
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppTheme.warning, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سيظهر الإشعار للمستخدمين فوراً عند فتحهم التطبيق',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _targetOption({
    required String value,
    required IconData icon,
    required Color color,
    required String label,
    required String subtitle,
  }) {
    final isSelected = _target == value;
    return GestureDetector(
      onTap: () => setState(() => _target = value),
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}

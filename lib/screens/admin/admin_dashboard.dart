import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import '../../services/reports_service.dart';
import '../../utils/app_theme.dart';
import 'manage_banners_screen.dart';
import 'manage_categories_screen.dart';
import 'manage_featured_screen.dart';
import 'manage_icons_screen.dart';
import 'manage_sort_options_screen.dart';
import 'manage_updates_screen.dart';
import '../../services/update_checker_service.dart';
import 'manage_users_screen.dart';
import 'moderate_photos_screen.dart';
import 'platform_earnings_screen.dart';
import 'send_notification_screen.dart';
import 'view_reports_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, int>? _stats;
  int _pendingReports = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await ProfileService().getStats();
      final reports = await ReportsService().getPendingCount();
      if (mounted) {
        setState(() {
          _stats = stats;
          _pendingReports = reports;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('لوحة الأدمن')),
        body: const Center(child: Text('هذه الصفحة متاحة للأدمن فقط')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('لوحة الأدمن')),
      body: RefreshIndicator(
        onRefresh: () async => await _loadStats(),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── معلومات ───
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
                          Icon(Icons.camera_alt,
                              color: AppTheme.warning, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'كأدمن، يمكنك أخذ لقطات شاشة داخل التطبيق',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── الإحصائيات ───
                    const Text('الإحصائيات',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _statCard('المستخدمون', _stats?['total_users'] ?? 0,
                            Icons.people, AppTheme.primary),
                        const SizedBox(width: 12),
                        _statCard('الصور', _stats?['total_photos'] ?? 0,
                            Icons.photo_library, AppTheme.secondary),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _statCard('إجمالي النقاط', _stats?['total_points'] ?? 0,
                        Icons.stars, AppTheme.accent),
                    const SizedBox(height: 24),

                    // ─── الإجراءات ───
                    const Text('الإجراءات',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // 🚨 البلاغات
                    _actionCardWithBadge(
                      'البلاغات',
                      'مراجعة بلاغات المستخدمين على الصور',
                      Icons.flag,
                      AppTheme.error,
                      _pendingReports,
                      () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ViewReportsScreen(),
                          ),
                        );
                        _loadStats();
                      },
                    ),
                    const SizedBox(height: 12),

                    // ═══════════════════════════════════════════
                    // 🎨 إدارة الأيقونات (جديد)
                    // ═══════════════════════════════════════════
                    _actionCard(
                      'إدارة الأيقونات',
                      'إضافة، تعديل، تسعير، تعطيل أيقونات المتجر',
                      Icons.emoji_emotions,
                      const Color(0xFFFFB800),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageIconsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    _actionCard(
                      '🧪 اختبار فحص التحديثات',
                      'اعرض معلومات المقارنة (للتشخيص)',
                      Icons.bug_report,
                      AppTheme.warning,
                      () => _showUpdateDebug(),
                    ),
                    const SizedBox(height: 12),

                    _actionCard(


                      'إدارة التحديثات',


                      'نشر تحديثات وإيقاف النسخ القديمة',


                      Icons.system_update,


                      AppTheme.primary,


                      () {


                        Navigator.push(


                          context,


                          MaterialPageRoute(


                            builder: (_) => const ManageUpdatesScreen(),


                          ),


                        );


                      },


                    ),


                    const SizedBox(height: 12),



                    _actionCard('إرسال إشعار للمستخدمين',
                        'إرسال إشعار جماعي أو لمستخدم محدد',
                        Icons.notifications_active, AppTheme.error, () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SendNotificationScreen()));
                    }),
                    const SizedBox(height: 12),

                    _actionCard('إدارة المستخدمين',
                        'تعديل النقاط، الحظر، ترقية أدمن',
                        Icons.manage_accounts, AppTheme.primary, () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ManageUsersScreen()));
                    }),
                    const SizedBox(height: 12),

                    _actionCard('الإشراف على الصور',
                        'تعديل، حذف، مراجعة الصور المخالفة',
                        Icons.gavel, AppTheme.secondary, () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ModeratePhotosScreen()));
                    }),
                    const SizedBox(height: 12),

                    _actionCard('إدارة التصنيفات',
                        'إضافة، تعديل، تفعيل/تعطيل تصنيفات الصور',
                        Icons.category, AppTheme.success, () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ManageCategoriesScreen()));
                    }),
                    const SizedBox(height: 12),

                    _actionCard('إدارة خيارات الفرز',
                        'إضافة، تعديل، تفعيل/تعطيل خيارات الفرز',
                        Icons.sort, AppTheme.accent, () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ManageSortOptionsScreen()));
                    }),
                    const SizedBox(height: 12),

                    _actionCard('أرباح المنصة',
                        'إجمالي العمولات وتفاصيلها',
                        Icons.account_balance_wallet, AppTheme.success, () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const PlatformEarningsScreen()));
                    }),
                    const SizedBox(height: 12),

                    _actionCard('الصور المميزة',
                        'إدارة الصور التي تظهر في الكاروسيل',
                        Icons.star, AppTheme.warning, () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ManageFeaturedScreen()));
                    }),
                    const SizedBox(height: 12),

                    _actionCard('إدارة البانرات',
                        'الصور العلوية + التمرير التلقائي',
                        Icons.view_carousel, AppTheme.secondary, () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ManageBannersScreen()));
                    }),
                  ],
                ),
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 🧪 أداة تشخيص نظام التحديثات
  // ═══════════════════════════════════════════════
  Future<void> _showUpdateDebug() async {
    // عرض مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await UpdateCheckerService().check();

      if (!mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.bug_report, color: AppTheme.warning),
              SizedBox(width: 10),
              Text('تشخيص التحديثات', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _debugRow(
                  'إصدار التطبيق الحالي',
                  '${result.currentCode}',
                ),
                _debugRow(
                  'أحدث إصدار في DB',
                  result.latestCode?.toString() ?? 'غير موجود',
                ),
                const Divider(height: 24),
                _debugRow(
                  'سيظهر الديالوج؟',
                  result.shouldShow ? '✅ نعم' : '❌ لا',
                  valueColor: result.shouldShow
                      ? AppTheme.success
                      : AppTheme.error,
                ),
                _debugRow(
                  'السبب',
                  result.reason.arabicLabel,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _reasonHint(result.reason),
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await UpdateCheckerService().resetSeenVersions();
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم مسح سجل الإصدارات المرئية'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('إعادة تعيين'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  String _reasonHint(UpdateCheckReason reason) {
    switch (reason) {
      case UpdateCheckReason.noActiveVersions:
        return 'لا يوجد تحديث نشط في قاعدة البيانات. أنشئ تحديثاً من "إدارة التحديثات".';
      case UpdateCheckReason.upToDate:
        return 'التطبيق محدّث بالفعل. لن يظهر الديالوج حتى تنشر إصداراً أعلى.';
      case UpdateCheckReason.mandatory:
        return 'تحديث إلزامي متوفر — سيظهر الديالوج في كل مرة حتى يتم التحديث.';
      case UpdateCheckReason.optionalNew:
        return 'تحديث اختياري جديد — سيظهر مرة واحدة لكل إصدار.';
      case UpdateCheckReason.alreadySeen:
        return 'المستخدم رأى الديالوج سابقاً — لن يظهر مجدداً إلا إذا رفعت الإصدار.';
      case UpdateCheckReason.error:
        return 'حدث خطأ أثناء الفحص. تحقق من اتصال الإنترنت وإعدادات Supabase.';
    }
  }

  Widget _debugRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor,
                fontWeight: valueColor != null ? FontWeight.bold : null,
              ),
              textDirection: TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text('$value',
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(String title, String subtitle, IconData icon, Color color,
      VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }

  Widget _actionCardWithBadge(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    int badgeCount,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            if (badgeCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount جديد',
                  style: const TextStyle(
                    color: AppTheme.error,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}

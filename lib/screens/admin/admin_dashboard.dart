import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import '../../services/reports_service.dart';
import '../../utils/app_theme.dart';
import 'manage_banners_screen.dart';
import 'manage_categories_screen.dart';
import 'manage_featured_screen.dart';
import 'manage_sort_options_screen.dart';
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

                    // 🚨 البلاغات (مع شارة عدد)
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

  // ⭐ بطاقة مع شارة عدد
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

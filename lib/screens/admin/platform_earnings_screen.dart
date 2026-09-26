import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/platform_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class PlatformEarningsScreen extends StatefulWidget {
  const PlatformEarningsScreen({super.key});

  @override
  State<PlatformEarningsScreen> createState() =>
      _PlatformEarningsScreenState();
}

class _PlatformEarningsScreenState extends State<PlatformEarningsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlatformProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أرباح المنصة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PlatformProvider>().fetchAll(),
          ),
        ],
      ),
      body: Consumer<PlatformProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.stats == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final s = provider.stats;
          if (s == null) {
            return const Center(child: Text('لا توجد بيانات'));
          }

          return RefreshIndicator(
            onRefresh: () async => await provider.fetchAll(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── الإجمالي الرئيسي ───
                  _bigCard(
                    'إجمالي العمولات',
                    s.totalCommission,
                    Icons.account_balance,
                    const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ─── حجم المبيعات ───
                  Row(
                    children: [
                      _smallCard(
                        'عدد المبيعات',
                        '${s.totalSales}',
                        Icons.shopping_bag,
                        AppTheme.accent,
                      ),
                      const SizedBox(width: 12),
                      _smallCard(
                        'حجم المبيعات',
                        s.totalVolume.toInt().toString(),
                        Icons.trending_up,
                        AppTheme.success,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ─── التفصيل الزمني ───
                  const Text(
                    'التفصيل الزمني',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _periodRow(
                    'اليوم',
                    s.todayCommission,
                    Icons.today,
                  ),
                  const SizedBox(height: 8),
                  _periodRow(
                    'آخر 7 أيام',
                    s.weekCommission,
                    Icons.calendar_view_week,
                  ),
                  const SizedBox(height: 8),
                  _periodRow(
                    'آخر 30 يوماً',
                    s.monthCommission,
                    Icons.calendar_month,
                  ),

                  const SizedBox(height: 24),

                  // ─── آخر العمولات ───
                  const Text(
                    'آخر العمولات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (provider.earnings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('لا توجد عمولات بعد'),
                      ),
                    )
                  else
                    Card(
                      child: Column(
                        children: provider.earnings
                            .map((e) => ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.success
                                        .withValues(alpha: 0.15),
                                    child: const Icon(
                                      Icons.attach_money,
                                      color: AppTheme.success,
                                    ),
                                  ),
                                  title: Text(
                                    '+${e.commissionAmount.toInt()} نقطة',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.success,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'من عملية بـ ${e.photoPrice.toInt()} نقطة '
                                    '(${(e.commissionRate * 100).toInt()}%)',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Text(
                                    Helpers.timeAgo(e.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _bigCard(String label, double value, IconData icon, Gradient gradient) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const Spacer(),
              const Icon(Icons.workspace_premium,
                  color: Colors.white70, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '${value.toInt()} نقطة',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallCard(String label, String value, IconData icon, Color color) {
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
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _periodRow(String label, double value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            '${value.toInt()} نقطة',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }
}

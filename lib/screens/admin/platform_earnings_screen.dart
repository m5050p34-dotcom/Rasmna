import 'package:flutter/material.dart';

import '../../services/platform_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class PlatformEarningsScreen extends StatefulWidget {
  const PlatformEarningsScreen({super.key});

  @override
  State<PlatformEarningsScreen> createState() =>
      _PlatformEarningsScreenState();
}

class _PlatformEarningsScreenState extends State<PlatformEarningsScreen> {
  final _service = PlatformService();

  Map<String, int>? _stats;
  List<Map<String, dynamic>> _earnings = [];
  List<Map<String, dynamic>> _dailyStats = [];
  String _filter = 'all';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await _service.getStats();
      final earnings = await _service.getEarnings(source: _filter);
      final daily = await _service.getDailyStats();

      if (mounted) {
        setState(() {
          _stats = stats;
          _earnings = earnings;
          _dailyStats = daily;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _applyFilter(String filter) async {
    setState(() {
      _filter = filter;
      _loading = true;
    });
    try {
      final earnings = await _service.getEarnings(source: filter);
      if (mounted) {
        setState(() {
          _earnings = earnings;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أرباح المنصة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && _stats == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildMainBalanceCard(),
                  const SizedBox(height: 16),
                  _buildPeriodCards(),
                  const SizedBox(height: 20),
                  _buildBreakdownSection(),
                  const SizedBox(height: 20),
                  _buildChartSection(),
                  const SizedBox(height: 20),
                  _buildFilterChips(),
                  const SizedBox(height: 12),
                  _buildTransactionsList(),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 💰 بطاقة الرصيد الرئيسي
  // ═══════════════════════════════════════════════
  Widget _buildMainBalanceCard() {
    final total = _stats?['total'] ?? 0;
    final adminBalance = _stats?['admin_balance'] ?? 0;
    final count = _stats?['count'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.success, Color(0xFF16A34A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.success.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up,
                  color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Text(
                'إجمالي أرباح المنصة',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.stars, color: Colors.amber, size: 32),
              const SizedBox(width: 8),
              Text(
                _formatNumber(total),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'نقطة',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet,
                    color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  'رصيد الأدمن الحالي: ${_formatNumber(adminBalance)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'من $count عملية شراء',
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 📅 بطاقات الفترات
  // ═══════════════════════════════════════════════
  Widget _buildPeriodCards() {
    return Row(
      children: [
        _periodCard(
          'اليوم',
          _stats?['today'] ?? 0,
          Icons.today,
          AppTheme.primary,
        ),
        const SizedBox(width: 8),
        _periodCard(
          'الأسبوع',
          _stats?['week'] ?? 0,
          Icons.date_range,
          AppTheme.secondary,
        ),
        const SizedBox(width: 8),
        _periodCard(
          'الشهر',
          _stats?['month'] ?? 0,
          Icons.calendar_month,
          AppTheme.accent,
        ),
      ],
    );
  }

  Widget _periodCard(
    String label,
    int value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              _formatNumber(value),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 📊 تفصيل المصادر
  // ═══════════════════════════════════════════════
  Widget _buildBreakdownSection() {
    final items = [
      _BreakdownItem(
        'شراء الصور',
        _stats?['photos'] ?? 0,
        Icons.photo_library,
        AppTheme.primary,
        'photo',
      ),
      _BreakdownItem(
        'شراء الأيقونات',
        _stats?['icons'] ?? 0,
        Icons.emoji_emotions,
        const Color(0xFFFFB800),
        'icon',
      ),
      _BreakdownItem(
        'تغيير الأسماء',
        _stats?['username'] ?? 0,
        Icons.edit,
        AppTheme.secondary,
        'username_change',
      ),
      _BreakdownItem(
        'تغيير الصور الرمزية',
        _stats?['avatar'] ?? 0,
        Icons.face,
        AppTheme.accent,
        'avatar_change',
      ),
      _BreakdownItem(
        'عمولات التحويل',
        _stats?['commission'] ?? 0,
        Icons.swap_horiz,
        AppTheme.warning,
        'transfer_commission',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.pie_chart, color: AppTheme.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'تفصيل المصادر',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map(_buildBreakdownTile),
      ],
    );
  }

  Widget _buildBreakdownTile(_BreakdownItem item) {
    final total = _stats?['total'] ?? 0;
    final percent = total > 0 ? (item.amount / total * 100) : 0.0;

    return GestureDetector(
      onTap: () => _applyFilter(item.source),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatNumber(item.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: item.color,
                      ),
                    ),
                    Text(
                      '${percent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (total > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.amount / total,
                  minHeight: 6,
                  backgroundColor: item.color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(item.color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 📈 الرسم البياني للأيام
  // ═══════════════════════════════════════════════
  Widget _buildChartSection() {
    if (_dailyStats.isEmpty) return const SizedBox.shrink();

    final maxAmount = _dailyStats
        .map((e) => e['amount'] as int)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'آخر 7 أيام',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _dailyStats.map((d) {
                final amount = d['amount'] as int;
                final height = maxAmount > 0
                    ? (amount / maxAmount) * 100
                    : 0.0;
                final date = (d['date'] as String).split('-').last;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$amount',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 24,
                      height: height.clamp(4.0, 100.0),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.success,
                            Color(0xFF16A34A),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 9,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 🔍 فلتر النوع
  // ═══════════════════════════════════════════════
  Widget _buildFilterChips() {
    final filters = [
      ('all', 'الكل', Icons.apps),
      ('photo', 'صور', Icons.photo_library),
      ('icon', 'أيقونات', Icons.emoji_emotions),
      ('username_change', 'أسماء', Icons.edit),
      ('avatar_change', 'صور رمزية', Icons.face),
      ('transfer_commission', 'عمولات', Icons.swap_horiz),
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _filter == f.$1;

          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 6,
              right: index == filters.length - 1 ? 0 : 6,
            ),
            child: FilterChip(
              selected: isSelected,
              onSelected: (_) => _applyFilter(f.$1),
              avatar: Icon(
                f.$3,
                size: 16,
                color: isSelected ? AppTheme.primary : null,
              ),
              label: Text(f.$2),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
              selectedColor: AppTheme.primary.withValues(alpha: 0.15),
              checkmarkColor: AppTheme.primary,
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 📋 قائمة العمليات
  // ═══════════════════════════════════════════════
  Widget _buildTransactionsList() {
    if (_earnings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long,
                size: 48, color: Theme.of(context).disabledColor),
            const SizedBox(height: 12),
            const Text('لا توجد عمليات في هذه الفئة'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.receipt_long,
                color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'سجل العمليات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${_earnings.length} عملية',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._earnings.map(_buildTransactionTile),
      ],
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> earning) {
    final source = earning['source'] as String? ?? '';
    final amount = (earning['amount'] as num?)?.toInt() ?? 0;
    final username = earning['username'] as String? ?? 'مستخدم';
    final description = earning['description'] as String? ?? '';
    final createdAt = earning['created_at'] as String?;

    final config = _configFor(source);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: config.color.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(config.icon, color: config.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description.isNotEmpty ? description : config.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.person, size: 11, color: Colors.grey),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        username,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).disabledColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        Helpers.timeAgo(DateTime.parse(createdAt)),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: AppTheme.success, size: 12),
                const SizedBox(width: 2),
                Text(
                  '$amount',
                  style: const TextStyle(
                    color: AppTheme.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _SourceConfig _configFor(String source) {
    switch (source) {
      case 'icon':
        return _SourceConfig(
            'شراء أيقونة', Icons.emoji_emotions, const Color(0xFFFFB800));
      case 'photo':
        return _SourceConfig(
            'شراء صورة', Icons.photo_library, AppTheme.primary);
      case 'username_change':
        return _SourceConfig('تغيير اسم', Icons.edit, AppTheme.secondary);
      case 'avatar_change':
        return _SourceConfig(
            'تغيير صورة رمزية', Icons.face, AppTheme.accent);
      case 'transfer_commission':
        return _SourceConfig(
            'عمولة تحويل', Icons.swap_horiz, AppTheme.warning);
      default:
        return _SourceConfig('إيراد', Icons.attach_money, Colors.grey);
    }
  }

  String _formatNumber(int n) {
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}K';
    }
    return '$n';
  }
}

class _BreakdownItem {
  final String label;
  final int amount;
  final IconData icon;
  final Color color;
  final String source;

  _BreakdownItem(this.label, this.amount, this.icon, this.color, this.source);
}

class _SourceConfig {
  final String label;
  final IconData icon;
  final Color color;

  _SourceConfig(this.label, this.icon, this.color);
}

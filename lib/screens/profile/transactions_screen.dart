import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/points_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTransactions());
  }

  void _loadTransactions() {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      context.read<PointsProvider>().fetchUserTransactions(userId);
    }
  }

  IconData _iconFor(String type, bool isCredit) {
    switch (type) {
      case AppConstants.txDailyLogin:
        return Icons.card_giftcard;
      case AppConstants.txPurchase:
        return Icons.shopping_bag;
      case AppConstants.txSale:
        return Icons.sell;
      case AppConstants.txAdminGrant:
        return Icons.admin_panel_settings;
      case AppConstants.txAdminDeduct:
        return Icons.gavel;
      case AppConstants.txAdminSet:
        return Icons.edit;
      case AppConstants.txWelcomeBonus:
        return Icons.emoji_events;
      case AppConstants.txTransferSent:
        return Icons.send;
      case AppConstants.txTransferReceived:
        return Icons.card_giftcard;
      case AppConstants.txTransferCommission:
        return Icons.account_balance_wallet;
      case AppConstants.txUsernameChange:
        return Icons.person;
      case AppConstants.txAvatarChange:
        return Icons.camera_alt;
      case AppConstants.txRefund:
        return Icons.replay;
      case AppConstants.txPenalty:
        return Icons.warning;
      default:
        return isCredit ? Icons.add : Icons.remove;
    }
  }

  Color _colorFor(String type, bool isCredit) {
    if (type == AppConstants.txTransferCommission ||
        type == AppConstants.txPlatformCommission ||
        type == AppConstants.txAdminGrant) {
      return AppTheme.warning;
    }
    if (type == AppConstants.txTransferReceived) {
      return AppTheme.secondary;
    }
    if (type == AppConstants.txSale) {
      return AppTheme.success;
    }
    return isCredit ? AppTheme.success : AppTheme.error;
  }

  List<Map<String, String>> _filters() {
    return [
      {'key': 'all', 'label': 'الكل'},
      {'key': AppConstants.txDailyLogin, 'label': 'مكافآت'},
      {'key': AppConstants.txTransferSent, 'label': 'تحويلات'},
      {'key': AppConstants.txPurchase, 'label': 'مشتريات'},
      {'key': AppConstants.txSale, 'label': 'مبيعات'},
    ];
  }

  bool _matchesFilter(String type) {
    if (_filterType == 'all') return true;
    if (_filterType == AppConstants.txTransferSent) {
      return type == AppConstants.txTransferSent ||
          type == AppConstants.txTransferReceived ||
          type == AppConstants.txTransferCommission;
    }
    return type == _filterType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل النقاط'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: Consumer2<AuthProvider, PointsProvider>(
        builder: (context, auth, points, _) {
          final transactions = points.userTransactions
              .where((tx) => _matchesFilter(tx.type))
              .toList();

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.stars,
                          color: Colors.amber, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'رصيدك الحالي',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                        Text(
                          '${auth.profile?.points ?? 0} نقطة',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _filters().length,
                  itemBuilder: (context, index) {
                    final filter = _filters()[index];
                    final isSelected = _filterType == filter['key'];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(filter['label']!),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _filterType = filter['key']!);
                        },
                        selectedColor:
                            AppTheme.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppTheme.primary,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildList(points, transactions)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(PointsProvider provider, List<dynamic> transactions) {
    if (provider.isLoading && provider.userTransactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transactions.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => _loadTransactions(),
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 80,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'لا توجد حركات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ستظهر هنا كل حركات النقاط',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadTransactions(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: transactions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final tx = transactions[index];
          final isCredit = tx.amount > 0;
          final color = _colorFor(tx.type, isCredit);
          final label = AppConstants.txLabels[tx.type]?['ar'] ?? tx.type;

          return Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconFor(tx.type, isCredit),
                  color: color,
                  size: 22,
                ),
              ),
              title: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tx.reason != null && tx.reason!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      tx.reason!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    Helpers.timeAgo(tx.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tx.amountLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                  Text(
                    'الرصيد: ${tx.balanceAfter}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).disabledColor,
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
}

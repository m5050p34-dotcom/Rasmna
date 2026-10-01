import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/icon_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/icon_store_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import '../../utils/translations.dart';

class IconStoreScreen extends StatefulWidget {
  const IconStoreScreen({super.key});

  @override
  State<IconStoreScreen> createState() => _IconStoreScreenState();
}

class _IconStoreScreenState extends State<IconStoreScreen> {
  final _service = IconStoreService();
  List<IconModel> _icons = [];
  Set<String> _ownedIconIds = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final uid = auth.userId;

      // 1) جلب الأيقونات المتاحة
      final icons = await _service.getAllIcons(onlyActive: true);

      // 2) جلب الأيقونات التي يملكها المستخدم النشطة
      Set<String> owned = {};
      if (uid != null) {
        final history = await _service.getUserIconHistory(uid);
        owned = history
            .where((h) => h.isCurrentlyValid)
            .map((h) => h.iconId)
            .toSet();
      }

      if (mounted) {
        setState(() {
          _icons = icons;
          _ownedIconIds = owned;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = Helpers.errorMessage(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(T.get(context, 'icon_store')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: T.get(context, 'refresh'),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildActiveIconCard(),
                      const SizedBox(height: 20),
                      _buildSectionTitle(),
                      const SizedBox(height: 12),
                      if (_icons.isEmpty)
                        _buildEmpty()
                      else
                        ..._icons.map((icon) => _buildIconCard(icon)),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  // ═══════════════════════════════════════════════
  // 🎨 بطاقة الأيقونة النشطة الحالية
  // ═══════════════════════════════════════════════
  Widget _buildActiveIconCard() {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    if (profile == null) return const SizedBox.shrink();
    final hasIcon = auth.hasActiveIcon;
    final daysLeft = auth.activeIconDaysRemaining;
    final expiringSoon = auth.isActiveIconExpiringSoon;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasIcon
              ? [AppTheme.primary, AppTheme.secondary]
              : [
                  Colors.grey.withValues(alpha: 0.3),
                  Colors.grey.withValues(alpha: 0.15),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (hasIcon ? AppTheme.primary : Colors.grey)
                .withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── العنوان والرصيد ───
          Row(
            children: [
              const Icon(Icons.account_circle,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  T.get(context, 'your_active_icon'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              // الرصيد
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars,
                        color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${profile.points}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ─── المحتوى ───
          if (hasIcon)
            Row(
              children: [
                // الأيقونة
                Container(
                  width: 60,
                  height: 60,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: expiringSoon
                          ? [AppTheme.error, AppTheme.warning]
                          : [
                              const Color(0xFFFFD700),
                              const Color(0xFFFFA500),
                            ],
                    ),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: profile.activeIconUrl ?? '',
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            expiringSoon
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle,
                            color: expiringSoon
                                ? AppTheme.warning
                                : Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            expiringSoon
                                ? '${T.get(context, 'icon_expiring_soon')} • $daysLeft ${T.get(context, 'icon_days')}'
                                : '$daysLeft ${T.get(context, 'icon_days_remaining')}',
                            style: TextStyle(
                              color: expiringSoon
                                  ? AppTheme.warning
                                  : Colors.white70,
                              fontSize: 12,
                              fontWeight: expiringSoon
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_emotions_outlined,
                    color: Colors.white54,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        T.get(context, 'no_active_icon'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        T.get(context, 'no_active_icon_hint'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 📢 عنوان القسم
  // ═══════════════════════════════════════════════
  Widget _buildSectionTitle() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          T.get(context, 'icon_store_tagline'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // 🎴 بطاقة أيقونة واحدة
  // ═══════════════════════════════════════════════
  Widget _buildIconCard(IconModel icon) {
    final auth = context.watch<AuthProvider>();
    final userPoints = auth.profile?.points ?? 0;
    final isOwned = _ownedIconIds.contains(icon.id);
    final canAfford = userPoints >= icon.price;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isOwned ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isOwned
            ? BorderSide(color: AppTheme.success.withValues(alpha: 0.4))
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // ─── صورة الأيقونة ───
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isOwned
                          ? [AppTheme.success, AppTheme.success]
                          : [
                              const Color(0xFFFFD700),
                              const Color(0xFFFFA500),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isOwned
                                ? AppTheme.success
                                : const Color(0xFFFFD700))
                            .withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: icon.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          size: 24,
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  ),
                ),
                // شارة "مملوكة"
                if (isOwned)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // ─── التفاصيل ───
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    icon.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (icon.description != null &&
                      icon.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        icon.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).disabledColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 8),

                  // ─── السعر والمدة ───
                  Row(
                    children: [
                      const Icon(Icons.stars,
                          size: 16, color: AppTheme.accent),
                      const SizedBox(width: 4),
                      Text(
                        '${icon.price}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 10, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${icon.durationDays} ${T.get(context, 'icon_days')}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── زر الشراء ───
            if (isOwned)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        color: AppTheme.success, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'مملوكة',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              ElevatedButton(
                onPressed: canAfford ? () => _confirmPurchase(icon) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford
                      ? AppTheme.primary
                      : Colors.grey.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_cart, size: 18),
                    const SizedBox(height: 2),
                    Text(
                      canAfford
                          ? T.get(context, 'buy_now')
                          : T.get(context, 'insufficient_points'),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ❌ لا توجد أيقونات
  // ═══════════════════════════════════════════════
  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_emotions_outlined,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 12),
          Text(
            T.get(context, 'no_icons_yet'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            T.get(context, 'no_icons_hint'),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).disabledColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text(T.get(context, 'retry')),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 🛒 نافذة تأكيد الشراء
  // ═══════════════════════════════════════════════
  Future<void> _confirmPurchase(IconModel icon) async {
    final auth = context.read<AuthProvider>();
    final userPoints = auth.profile?.points ?? 0;
    final remaining = userPoints - icon.price;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart,
                  color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                T.get(context, 'purchase_icon'),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // صورة الأيقونة
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: icon.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              icon.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (icon.description != null &&
                icon.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  icon.description!,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),

            // السعر
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(T.get(context, 'icon_price')),
                      Row(
                        children: [
                          const Icon(Icons.stars,
                              size: 16, color: AppTheme.accent),
                          const SizedBox(width: 4),
                          Text(
                            '${icon.price}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(T.get(context, 'points_balance')),
                      Text(
                        '$userPoints',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'المتبقي بعد الشراء',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '$remaining',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // تنبيه المدة
            Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppTheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${T.get(context, 'icon_valid_until')}: ${icon.durationDays} ${T.get(context, 'icon_days')}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(T.get(context, 'cancel')),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check, size: 18),
            label: Text(T.get(context, 'confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _executePurchase(icon);
  }

  Future<void> _executePurchase(IconModel icon) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider>();

    // عرض مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      final result = await _service.purchaseIcon(icon.id);
      await auth.refreshAfterPurchase();

      if (!mounted) return;
      navigator.pop();

      _showSuccessDialog(result);
      await _load();
    } catch (e) {
      if (!mounted) return;
      navigator.pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text(Helpers.errorMessage(e)),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccessDialog(PurchaseIconResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              T.get(context, 'purchase_success'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.iconName,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars,
                      color: AppTheme.accent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${result.newBalance} ${T.get(context, 'points')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(T.get(context, 'close')),
          ),
        ],
      ),
    );
  }
}

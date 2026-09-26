import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';

class DailyRewardWidget extends StatefulWidget {
  const DailyRewardWidget({super.key});

  @override
  State<DailyRewardWidget> createState() => _DailyRewardWidgetState();
}

class _DailyRewardWidgetState extends State<DailyRewardWidget> {
  bool _isClaiming = false;

  Future<void> _claimReward() async {
    // ✅ التقاط المراجع قبل أي await
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isClaiming = true);

    try {
      final result = await auth.claimDailyReward();

      if (!mounted || result == null) return;

      // إغلاق الدرج أولاً
      navigator.pop();

      // ✅ استخدام this.context بعد فحص mounted
      if (!mounted) return;
      showDialog(
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
                  color: AppTheme.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.card_giftcard,
                    color: AppTheme.success, size: 28),
              ),
              const SizedBox(width: 12),
              const Text('مبروك! 🎉'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+${result.earnedPoints} نقطة',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'اليوم ${result.day} من 7',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(ctx).textTheme.bodyMedium?.color,
                ),
              ),
              if (result.isWeekComplete) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.emoji_events,
                          color: AppTheme.warning, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'أكملت الأسبوع! 🏆',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('رائع!'),
            ),
          ],
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(Helpers.errorMessage(e)),
          backgroundColor: AppTheme.warning,
        ),
      );
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final profile = auth.profile;
        if (profile == null) return const SizedBox.shrink();

        final canClaim = profile.canClaimDailyReward;
        final currentStreak = profile.loginStreak;
        final nextDay = profile.nextRewardDay;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primary.withValues(alpha: 0.1),
                AppTheme.secondary.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══════════════════════════════════
              // العنوان
              // ═══════════════════════════════════
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.card_giftcard,
                      color: AppTheme.warning,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'المكافأة اليومية',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$currentStreak / 7',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ═══════════════════════════════════
              // 7 مربعات
              // ═══════════════════════════════════
              Row(
                children: List.generate(7, (index) {
                  final dayNumber = index + 1;
                  final points = dayNumber * 10;

                  final isClaimed = dayNumber <= currentStreak;
                  final isCurrent = canClaim && dayNumber == nextDay;
                  final isPast = dayNumber < nextDay && !canClaim;

                  Color bgColor;
                  Color textColor;
                  Color borderColor;

                  if (isClaimed || isPast) {
                    bgColor = AppTheme.success.withValues(alpha: 0.15);
                    textColor = AppTheme.success;
                    borderColor = AppTheme.success;
                  } else if (isCurrent) {
                    bgColor = AppTheme.warning;
                    textColor = Colors.white;
                    borderColor = AppTheme.warning;
                  } else {
                    bgColor = Colors.grey.withValues(alpha: 0.1);
                    textColor = Colors.grey;
                    borderColor = Colors.grey.withValues(alpha: 0.3);
                  }

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 0 : 2,
                        right: index == 6 ? 0 : 2,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 2,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: borderColor,
                            width: isCurrent ? 2 : 1,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: AppTheme.warning
                                        .withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (isClaimed || isPast)
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: textColor,
                              )
                            else if (isCurrent)
                              const Icon(
                                Icons.redeem,
                                size: 16,
                                color: Colors.white,
                              )
                            else
                              Icon(
                                Icons.lock_outline,
                                size: 14,
                                color: textColor,
                              ),
                            const SizedBox(height: 2),
                            Text(
                              '$points',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 12),

              // ═══════════════════════════════════
              // زر الاستلام
              // ═══════════════════════════════════
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: canClaim && !_isClaiming ? _claimReward : null,
                  icon: _isClaiming
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          canClaim ? Icons.redeem : Icons.check_circle,
                          size: 18,
                        ),
                  label: Text(
                    _isClaiming
                        ? 'جارٍ الاستلام...'
                        : canClaim
                            ? 'استلام ${nextDay * 10} نقطة'
                            : 'تم استلام مكافأة اليوم',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canClaim ? AppTheme.primary : Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

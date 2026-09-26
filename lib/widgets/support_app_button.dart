import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads_service.dart';
import '../utils/app_theme.dart';

class SupportAppButton extends StatefulWidget {
  const SupportAppButton({super.key});

  @override
  State<SupportAppButton> createState() => _SupportAppButtonState();
}

class _SupportAppButtonState extends State<SupportAppButton> {
  bool _isLoading = false;
  RewardedAd? _rewardedAd;

  @override
  void initState() {
    super.initState();
    _preload();
  }

  Future<void> _preload() async {
    try {
      final ad = await AdsService().loadRewardedAd();
      if (mounted) {
        setState(() => _rewardedAd = ad);
      }
    } catch (_) {}
  }

  Future<void> _showAd() async {
    setState(() => _isLoading = true);

    _rewardedAd ??= await AdsService().loadRewardedAd();

    if (_rewardedAd == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يوجد إعلان متاح حالياً. حاول لاحقاً.'),
            backgroundColor: AppTheme.warning,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        if (mounted) {
          setState(() => _isLoading = false);
        }
        _preload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '❤️ شكراً لدعمك! حصلت على ${reward.amount} ${reward.type}',
              ),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isLoading ? null : _showAd,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.secondary, AppTheme.primary],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondary.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // ─── أيقونة / Spinner ───
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 20,
                        ),
                ),

                const SizedBox(width: 12),

                // ─── النصوص ───
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'ادعم التطبيق',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isLoading
                            ? 'جارٍ التحميل...'
                            : 'شاهد إعلاناً قصيراً لدعمنا ❤️',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // ─── سهم ───
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/banner_model.dart';
import '../providers/banner_provider.dart';
import '../screens/home/photo_details_screen.dart';
import '../utils/app_theme.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _currentPage = 0;
  int _lastBannerCount = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleAutoScroll(int intervalSeconds, int bannerCount) {
    if (_lastBannerCount == bannerCount && _timer != null) return;
    _lastBannerCount = bannerCount;
    _timer?.cancel();

    if (bannerCount <= 1 || intervalSeconds <= 0) return;

    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_currentPage + 1) % bannerCount;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  // ═══════════════════════════════════════════════
  // 🎯 معالجة الضغط على البانر
  // ═══════════════════════════════════════════════
  Future<void> _handleBannerTap(BannerModel banner) async {
    // 1️⃣ أولوية: الرابط الخارجي
    if (banner.hasValidExternalLink) {
      await _openExternalUrl(banner.linkUrl!.trim());
      return;
    }

    // 2️⃣ ثانياً: صورة داخل التطبيق
    if (banner.linkedPhoto != null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoDetailsScreen(photo: banner.linkedPhoto!),
        ),
      );
      return;
    }

    // 3️⃣ لا يوجد رابط
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد رابط لهذا البانر'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _openExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);

      if (!await canLaunchUrl(uri)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('لا يمكن فتح الرابط: $url'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
        return;
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل فتح الرابط: $url'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BannerProvider>(
      builder: (context, provider, _) {
        final banners = provider.activeBanners;
        if (banners.isEmpty) return const SizedBox.shrink();

        final settings = provider.settings;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scheduleAutoScroll(
              settings.bannerIntervalSeconds,
              banners.length,
            );
          }
        });

        final height = settings.bannerHeight.clamp(120, 400).toDouble();

        return SizedBox(
          height: height,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  return _buildBanner(context, banners[index]);
                },
              ),

              // ─── المؤشرات ───
              if (settings.showBannerDots && banners.length > 1)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      banners.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentPage == i ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
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

  Widget _buildBanner(BuildContext context, BannerModel banner) {
    return GestureDetector(
      onTap: () => _handleBannerTap(banner),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ─── الصورة ───
          CachedNetworkImage(
            imageUrl: banner.imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, __, ___) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image, size: 48),
            ),
          ),

          // ─── تدرج سفلي إذا كان هناك عنوان ───
          if (banner.title != null && banner.title!.isNotEmpty)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),

          // ─── العنوان ───
          if (banner.title != null && banner.title!.isNotEmpty)
            Positioned(
              bottom: 30,
              right: 20,
              left: 20,
              child: Text(
                banner.title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
                textAlign: TextAlign.right,
              ),
            ),

          // ─── شارة "مميز" ───
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.warning, AppTheme.accent],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'مميز',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── أيقونة الرابط (إذا كان هناك رابط) ───
          if (banner.hasValidExternalLink || banner.linkedPhoto != null)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  banner.hasValidExternalLink
                      ? Icons.open_in_new
                      : Icons.image,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

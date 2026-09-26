import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// ✅ Unity Ads Mediation
import 'package:gma_mediation_unity/gma_mediation_unity.dart';

class AdsService {
  static final AdsService _instance = AdsService._internal();
  factory AdsService() => _instance;
  AdsService._internal();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  // ✅ إنشاء نسخة من Unity mediation
  final GmaMediationUnity _unity = GmaMediationUnity();

  // ═══════════════════════════════════════════════
  // 🎯 معرّفات الإعلانات (AdMob)
  // ═══════════════════════════════════════════════
  static const String _testBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String _prodBannerId =
      'ca-app-pub-2593531118090866/1907768520';
  static const String _prodInterstitialId =
      'ca-app-pub-2593531118090866/2326481632';
  static const String _prodRewardedId =
      'ca-app-pub-2593531118090866/2378452521';

  bool get _useTestAds => kDebugMode;

  String get bannerAdUnitId =>
      _useTestAds ? _testBannerId : _prodBannerId;

  String get interstitialAdUnitId =>
      _useTestAds ? _testInterstitialId : _prodInterstitialId;

  String get rewardedAdUnitId =>
      _useTestAds ? _testRewardedId : _prodRewardedId;

  // ═══════════════════════════════════════════════
  // 🚀 تهيئة SDK
  // ═══════════════════════════════════════════════
  Future<void> initialize() async {
    if (_initialized) return;

    // ✅ Unity Ads - إعدادات الخصوصية (instance methods)
    try {
      await _unity.setGDPRConsent(true);
      await _unity.setCCPAConsent(true);
      debugPrint('✅ Unity Ads privacy configured');
    } catch (e) {
      debugPrint('⚠️ Unity Ads privacy error: $e');
    }

    if (Platform.isAndroid || Platform.isIOS) {
      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('🎬 AdMob 9.1.0 + Unity Ads mediation initialized');
      debugPrint('   Banner: $bannerAdUnitId');
      debugPrint('   Interstitial: $interstitialAdUnitId');
      debugPrint('   Rewarded: $rewardedAdUnitId');
    }
  }

  // ═══════════════════════════════════════════════
  // 📢 Banner Ad
  // ═══════════════════════════════════════════════
  BannerAd createBannerAd({
    required VoidCallback onLoaded,
    required Function(LoadAdError) onFailed,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          debugPrint('✅ Banner loaded');
          onLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Banner failed: ${error.message}');
          ad.dispose();
          onFailed(error);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 🎬 Interstitial Ad
  // ═══════════════════════════════════════════════
  Future<InterstitialAd?> loadInterstitialAd() async {
    InterstitialAd? ad;

    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (loaded) {
          debugPrint('✅ Interstitial loaded (AdMob/Unity)');
          ad = loaded;
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Interstitial failed: ${error.message}');
          ad = null;
        },
      ),
    );

    return ad;
  }

  // ═══════════════════════════════════════════════
  // 🎁 Rewarded Ad
  // ═══════════════════════════════════════════════
  Future<RewardedAd?> loadRewardedAd() async {
    RewardedAd? ad;

    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (loaded) {
          debugPrint('✅ Rewarded loaded (AdMob/Unity)');
          ad = loaded;
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Rewarded failed: ${error.message}');
          ad = null;
        },
      ),
    );

    return ad;
  }
}

class AppSettingsModel {
  final int bannerIntervalSeconds;
  final int bannerHeight;
  final bool showBannerDots;

  AppSettingsModel({
    required this.bannerIntervalSeconds,
    required this.bannerHeight,
    required this.showBannerDots,
  });

  factory AppSettingsModel.fromMap(Map<String, String> map) {
    return AppSettingsModel(
      bannerIntervalSeconds:
          int.tryParse(map['banner_interval_seconds'] ?? '7') ?? 7,
      bannerHeight: int.tryParse(map['banner_height'] ?? '220') ?? 220,
      showBannerDots: (map['show_banner_dots'] ?? 'true') == 'true',
    );
  }

  static AppSettingsModel defaults() => AppSettingsModel(
        bannerIntervalSeconds: 7,
        bannerHeight: 220,
        showBannerDots: true,
      );
}

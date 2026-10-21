/// Ad configuration: unit IDs, cadence, and tenure segmentation.
class AdConfig {
  // Test ad unit IDs — replace with production IDs before release.
  static const String bannerAdUnitIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String bannerAdUnitIdIos = 'ca-app-pub-3940256099942544/2934735716';
  static const String interstitialAdUnitIdAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String interstitialAdUnitIdIos = 'ca-app-pub-3940256099942544/4411468910';
  static const String rewardedAdUnitIdAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const String rewardedAdUnitIdIos = 'ca-app-pub-3940256099942544/1712485313';

  static String getBannerAdUnitId() {
    // Platform check would go here; returning Android for simplicity.
    return bannerAdUnitIdAndroid;
  }

  static String getInterstitialAdUnitId() {
    return interstitialAdUnitIdAndroid;
  }

  static String getRewardedAdUnitId() {
    return rewardedAdUnitIdAndroid;
  }

  /// Interstitial cooldown in seconds based on user tenure (days since first launch).
  /// Modeled on Meowdoku's smart ad segmentation.
  static int interstitialCooldownSeconds(int tenureDays) {
    if (tenureDays < 2) return 120;   // Days 0-2: gentle on new players
    if (tenureDays < 7) return 100;   // Days 2-7: moderate
    return 90;                        // Day 7+: more aggressive on retained users
  }

  /// Interstitials start showing from stage 10.
  static const int interstitialStartStage = 10;

  /// Banners start showing from stage 10.
  static const int bannerStartStage = 10;

  /// Rewarded ads available from stage 1.
  static const int rewardedStartStage = 1;
}

import '../../config/booster_config.dart';

/// Handles the rewarded-ad path for acquiring boosters.
class WatchAdForBoosterUseCase {
  /// Returns the ad reward amount for a booster, or 0 if not ad-purchasable.
  int getAdReward(String boosterId) {
    final config = BoosterConfig.getBooster(boosterId);
    if (config == null) return 0;
    return config['priceAd'] == true ? config['adRewardAmount'] as int : 0;
  }

  /// Whether a booster can be acquired by watching an ad.
  bool canBuyWithAd(String boosterId) {
    final config = BoosterConfig.getBooster(boosterId);
    return config?['priceAd'] == true;
  }
}

/// Booster definitions and pricing.
///
/// Boosters can be acquired with coins or by watching a rewarded ad.
class BoosterConfig {
  static const String hint = 'booster_hint';
  static const String extraLife = 'booster_extra_life';
  static const String revealCell = 'booster_reveal_cell';

  static const List<Map<String, dynamic>> allBoosters = [
    {
      'id': hint,
      'name': 'Hint',
      'description': 'Highlights a valid cell to place a bunny.',
      'icon': 'assets/images/booster/hint.svg',
      'coinPrice': 50,
      'priceAd': true, // can be bought by watching an ad
      'adRewardAmount': 1,
    },
    {
      'id': extraLife,
      'name': 'Extra Life',
      'description': 'Adds one extra heart to the current stage.',
      'icon': 'assets/images/booster/extra_life.svg',
      'coinPrice': 80,
      'priceAd': true,
      'adRewardAmount': 1,
    },
    {
      'id': revealCell,
      'name': 'Reveal Cell',
      'description': 'Reveals the correct bunny position in one region.',
      'icon': 'assets/images/booster/reveal.svg',
      'coinPrice': 120,
      'priceAd': true,
      'adRewardAmount': 1,
    },
  ];

  static Map<String, dynamic>? getBooster(String id) {
    try {
      return allBoosters.firstWhere((b) => b['id'] == id);
    } catch (_) {
      return null;
    }
  }
}

/// Remove Ads product ID.
const String removeAdsProductId = 'remove_ads';

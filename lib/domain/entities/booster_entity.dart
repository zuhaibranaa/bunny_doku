/// Domain entity for a booster.
class BoosterEntity {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int coinPrice;
  final bool priceAd;
  final int adRewardAmount;

  BoosterEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.coinPrice,
    required this.priceAd,
    required this.adRewardAmount,
  });
}

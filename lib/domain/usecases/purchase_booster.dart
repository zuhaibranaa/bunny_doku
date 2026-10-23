import '../../config/booster_config.dart';
import '../entities/booster_entity.dart';

/// Converts booster config to domain entities.
class PurchaseBoosterUseCase {
  /// Converts all booster configs to entities.
  List<BoosterEntity> getAllBoosters() {
    return BoosterConfig.allBoosters
        .map((c) => BoosterEntity(
              id: c['id'] as String,
              name: c['name'] as String,
              description: c['description'] as String,
              icon: c['icon'] as String,
              coinPrice: c['coinPrice'] as int,
              priceAd: c['priceAd'] as bool,
              adRewardAmount: c['adRewardAmount'] as int,
            ))
        .toList();
  }

  BoosterEntity? getBooster(String id) {
    final config = BoosterConfig.getBooster(id);
    if (config == null) return null;
    return BoosterEntity(
      id: config['id'] as String,
      name: config['name'] as String,
      description: config['description'] as String,
      icon: config['icon'] as String,
      coinPrice: config['coinPrice'] as int,
      priceAd: config['priceAd'] as bool,
      adRewardAmount: config['adRewardAmount'] as int,
    );
  }
}

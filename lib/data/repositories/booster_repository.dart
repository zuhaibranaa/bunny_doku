import '../../config/booster_config.dart';
import '../storage/local_storage.dart';

/// Repository for booster inventory and purchases.
class BoosterRepository {
  Future<void> initializeInventory() async {
    final inventory = LocalStorage.boosterInventoryRaw;
    if (inventory.isNotEmpty) return;

    // Initialize with 3 of each booster type on first time
    final initial = <Map<String, dynamic>>[];
    for (final config in BoosterConfig.allBoosters) {
      initial.add({
        'boosterId': config['id'] as String,
        'quantity': 3,
      });
    }
    await LocalStorage.setBoosterInventoryRaw(initial);
  }

  Future<void> loadInventory() async {
    final inventory = LocalStorage.boosterInventoryRaw;
    if (inventory.isNotEmpty) return;
    await initializeInventory();
  }

  int getBoosterQuantity(String boosterId) =>
      LocalStorage.getBoosterQuantity(boosterId);

  Future<void> addBooster(String boosterId, int quantity) async {
    await LocalStorage.addBoosterQuantity(boosterId, quantity);
  }

  Future<void> consumeBooster(String boosterId) async {
    await LocalStorage.consumeBoosterQuantity(boosterId);
  }

  List<Map<String, dynamic>> getAllInventory() =>
      LocalStorage.boosterInventoryRaw;
}

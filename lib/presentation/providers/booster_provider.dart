import 'package:flutter/foundation.dart';

import '../../data/repositories/booster_repository.dart';
import '../../domain/entities/booster_entity.dart';
import '../../config/booster_config.dart';

class BoosterProvider extends ChangeNotifier {
  final BoosterRepository _boosterRepo;

  Map<String, int> _inventory = {};
  bool _isLoading = true;
  List<BoosterEntity> _boosters = [];

  BoosterProvider({required BoosterRepository boosterRepo})
      : _boosterRepo = boosterRepo;

  Map<String, int> get inventory => _inventory;
  List<BoosterEntity> get boosters => _boosters;
  bool get isLoading => _isLoading;

  int getQuantity(String boosterId) => _inventory[boosterId] ?? 0;

  Future<void> loadInventory() async {
    _isLoading = true;
    notifyListeners();

    await _boosterRepo.initializeInventory();
    final inventoryList = _boosterRepo.getAllInventory();
    _inventory = {
      for (var e in inventoryList) e['boosterId'] as String: e['quantity'] as int,
    };
    _boosters = BoosterConfig.allBoosters
        .map((b) => BoosterEntity(
              id: b['id'] as String,
              name: b['name'] as String,
              description: b['description'] as String,
              icon: b['icon'] as String,
              priceUsd: (b['priceUsd'] as num).toDouble(),
              priceAd: b['priceAd'] as bool,
              adRewardAmount: b['adRewardAmount'] as int,
            ))
        .toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> consume(String boosterId) async {
    try {
      await _boosterRepo.consumeBooster(boosterId);
      _inventory.update(boosterId, (v) => v - 1, ifAbsent: () => 0);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> add(String boosterId, int quantity) async {
    await _boosterRepo.addBooster(boosterId, quantity);
    _inventory.update(
      boosterId,
      (v) => v + quantity,
      ifAbsent: () => quantity,
    );
    notifyListeners();
  }

  Future<void> addQuantity(String boosterId, int quantity) async {
    await add(boosterId, quantity);
  }

  Future<void> buyBooster(String boosterId) async {
    await add(boosterId, 1);
  }

  Future<void> buyBoosterWithAd(String boosterId) async {
    await add(boosterId, 1);
  }
}

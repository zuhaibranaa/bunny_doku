import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../config/booster_config.dart';
import '../models/stage_model.dart';
import '../models/user_model.dart';
import '../models/booster_model.dart';
import '../models/purchase_model.dart';
import '../models/stage_progress_model.dart';

/// Centralized local storage for Rabit_doku.
/// Uses shared_preferences with JSON serialization for all data.
class LocalStorage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('LocalStorage not initialized. Call LocalStorage.init() first.');
    }
    return _prefs!;
  }

  // ----- Keys -----
  static const String keyContentVersion = 'content_version';
  static const String keyUnlockedStageIndex = 'unlocked_stage_index';
  static const String keyAdTenureDay = 'ad_tenure_day';
  static const String keyIsAdsRemoved = 'is_ads_removed';
  static const String keyUserId = 'user_id';
  static const String keyUser = 'user';
  static const String keyStages = 'stages';
  static const String keyBoosters = 'boosters';
  static const String keyBoosterInventory = 'booster_inventory';
  static const String keyPurchases = 'purchases';
  static const String keyStageProgress = 'stage_progress';
  static const String keyFirstRun = 'first_run_done';
  static const String keyBoosterTutorialGiven = 'booster_tutorial_given';

  // ----- Content Version -----
  /// Stored content version, or 0 when unset so that the first
  /// `ReleaseConfig.contentVersion` bump always triggers a pack reload.
  static int get contentVersion => prefs.getInt(keyContentVersion) ?? 0;
  static Future<void> setContentVersion(int version) async {
    await prefs.setInt(keyContentVersion, version);
  }

  // ----- First Run -----
  static bool get firstRunDone => prefs.getBool(keyFirstRun) ?? false;
  static Future<void> setFirstRunDone(bool value) async {
    await prefs.setBool(keyFirstRun, value);
  }

  static bool get boosterTutorialGiven => prefs.getBool(keyBoosterTutorialGiven) ?? false;
  static Future<void> setBoosterTutorialGiven(bool value) async {
    await prefs.setBool(keyBoosterTutorialGiven, value);
  }

  // ----- Unlocked Stage -----
  static int get unlockedStageIndex =>
      prefs.getInt(keyUnlockedStageIndex) ?? 1;
  static Future<void> setUnlockedStageIndex(int index) async {
    await prefs.setInt(keyUnlockedStageIndex, index);
  }

  // ----- Ads Removed -----
  static bool get isAdsRemoved =>
      prefs.getBool(keyIsAdsRemoved) ?? false;
  static Future<void> setIsAdsRemoved(bool value) async {
    await prefs.setBool(keyIsAdsRemoved, value);
  }

  // ----- User ID -----
  static String get userId =>
      prefs.getString(keyUserId) ?? '';
  static Future<void> setUserId(String id) async {
    await prefs.setString(keyUserId, id);
  }

  // ----- User -----
  static UserModel? get user {
    final json = prefs.getString(keyUser);
    if (json == null) return null;
    return UserModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  static Future<void> setUser(UserModel user) async {
    await prefs.setString(keyUser, jsonEncode(user.toJson()));
  }

  // ----- Stages -----
  static List<StageModel> get stages {
    final jsonList = prefs.getStringList(keyStages) ?? [];
    return jsonList
        .map((j) => StageModel.fromJson(jsonDecode(j) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> setStages(List<StageModel> stageList) async {
    final jsonList = stageList.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(keyStages, jsonList);
  }

  // ----- Boosters (config) -----
  static List<BoosterModel> get boosterConfigs {
    final jsonList = prefs.getStringList(keyBoosters) ?? [];
    if (jsonList.isEmpty) {
      final configs = BoosterConfig.allBoosters;
      final models = configs.map((c) => BoosterModel.fromConfig(c)).toList();
      setBoosterConfigs(models); // fire and forget for init
      return models;
    }
    return jsonList
        .map((j) => BoosterModel.fromConfig(jsonDecode(j) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> setBoosterConfigs(List<BoosterModel> boosters) async {
    final jsonList = boosters.map((b) => jsonEncode(b.toJson())).toList();
    await prefs.setStringList(keyBoosters, jsonList);
  }

  // ----- Booster Inventory -----
  static List<Map<String, dynamic>> get boosterInventoryRaw {
    final jsonList = prefs.getStringList(keyBoosterInventory) ?? [];
    return jsonList
        .map((j) => jsonDecode(j) as Map<String, dynamic>)
        .toList();
  }

  static Future<void> setBoosterInventoryRaw(List<Map<String, dynamic>> inventory) async {
    final jsonList = inventory.map((i) => jsonEncode(i)).toList();
    await prefs.setStringList(keyBoosterInventory, jsonList);
  }

  static int getBoosterQuantity(String boosterId) {
    final inventory = boosterInventoryRaw;
    try {
      return inventory.firstWhere((e) => e['boosterId'] == boosterId)['quantity'] as int;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> setBoosterQuantity(String boosterId, int quantity) async {
    final inventory = boosterInventoryRaw;
    final index = inventory.indexWhere((e) => e['boosterId'] == boosterId);
    if (index >= 0) {
      inventory[index]['quantity'] = quantity;
    } else {
      inventory.add({'boosterId': boosterId, 'quantity': quantity});
    }
    await setBoosterInventoryRaw(inventory);
  }

  static Future<void> addBoosterQuantity(String boosterId, int amount) async {
    final current = getBoosterQuantity(boosterId);
    await setBoosterQuantity(boosterId, current + amount);
  }

  static Future<void> consumeBoosterQuantity(String boosterId) async {
    final current = getBoosterQuantity(boosterId);
    if (current <= 0) {
      throw StateError('No $boosterId booster available');
    }
    await setBoosterQuantity(boosterId, current - 1);
  }

  // ----- Purchases -----
  static List<PurchaseModel> get purchases {
    final jsonList = prefs.getStringList(keyPurchases) ?? [];
    return jsonList
        .map((j) => PurchaseModel.fromJson(jsonDecode(j) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addPurchase(PurchaseModel purchase) async {
    final existing = purchases;
    existing.add(purchase);
    final jsonList = existing.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(keyPurchases, jsonList);
  }

  // ----- Stage Progress -----
  static List<StageProgressModel> get stageProgress {
    final jsonList = prefs.getStringList(keyStageProgress) ?? [];
    return jsonList
        .map((j) => StageProgressModel.fromJson(jsonDecode(j) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> setStageProgress(List<StageProgressModel> progressList) async {
    final jsonList = progressList.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(keyStageProgress, jsonList);
  }

  static StageProgressModel? getStageProgress(int stageId) {
    final uid = userId;
    try {
      return stageProgress.firstWhere(
        (p) => p.stageId == stageId && p.id.startsWith(uid),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveStageProgress(StageProgressModel progress) async {
    final existing = stageProgress;
    existing.removeWhere((p) => p.id == progress.id);
    existing.add(progress);
    await setStageProgress(existing);
  }
}

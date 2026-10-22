import 'dart:async';

import '../../config/release_config.dart';
import '../../core/network/stage_api.dart';
import '../../core/storage/stage_cache.dart';
import '../../data/storage/local_storage.dart';
import '../../data/models/stage_model.dart';
import '../../data/models/stage_progress_model.dart';

/// Repository for stage data — single source of truth.
class StageRepository {
  final StageApi api;
  final RemoteConfigService remoteConfig;
  final StageCache cache;

  StageRepository({
    required this.api,
    required this.remoteConfig,
    required this.cache,
  });

  Future<List<StageModel>> initializeStages() async {
    final remoteVersion = await RemoteConfigService.checkContentVersion(api);
    final localVersion = LocalStorage.contentVersion;
    final cachedStages = cache.getCachedStages();

    // If no cached stages (first launch), load from bundled assets
    if (cachedStages.isEmpty) {
      final stageJsons = await api.fetchStagePack();
      final stages = stageJsons
          .map((json) => StageModel.fromJson(json))
          .toList();
      await cache.saveStages(stages);
      await LocalStorage.setContentVersion(ReleaseConfig.contentVersion);
      return stages;
    }

    // Remote version newer than local — download new stages
    if (remoteVersion != null && remoteVersion > localVersion) {
      final stageJsons = await api.fetchStagePack();
      final stages = stageJsons
          .map((json) => StageModel.fromJson(json))
          .toList();
      await cache.saveStages(stages);
      await LocalStorage.setContentVersion(remoteVersion);
      return stages;
    }

    return cachedStages;
  }

  List<StageModel> getAllStages() => cache.getCachedStages();

  StageModel? getStage(int id) => cache.getStageById(id);

  int getUnlockedStageIndex() {
    // Only progression-based unlocking: stage N+1 unlocks when stage N is completed.
    // All stages are locked initially except stage 1 (default unlockedStageIndex = 1).
    return LocalStorage.unlockedStageIndex;
  }

  Future<void> markStageCompleted(int stageId, {int stars = 0}) async {
    await LocalStorage.setUnlockedStageIndex(
      LocalStorage.unlockedStageIndex > stageId
          ? LocalStorage.unlockedStageIndex
          : stageId + 1,
    );

    final uid = LocalStorage.userId;
    final progressId = '${uid}_$stageId';
    final existing = LocalStorage.stageProgress;
    existing.removeWhere((p) => p.id == progressId);
    existing.add(StageProgressModel(
      id: progressId,
      stageId: stageId,
      starsEarned: stars,
      isCompleted: true,
      completedAt: DateTime.now(),
    ));
    await LocalStorage.setStageProgress(existing);
  }

  StageProgressModel? getStageProgress(int stageId) =>
      LocalStorage.getStageProgress(stageId);
}

class RemoteConfigService {
  static Future<int?> checkContentVersion(StageApi api) async =>
      StageApi.checkContentVersion(api);
}

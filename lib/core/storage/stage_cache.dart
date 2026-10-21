import '../../data/models/stage_model.dart';
import '../../data/storage/local_storage.dart';

/// Caches stage packs locally so stages are available offline.
class StageCache {
  Future<void> saveStages(List<StageModel> stages) async {
    await LocalStorage.setStages(stages);
  }

  List<StageModel> getCachedStages() {
    return LocalStorage.stages;
  }

  StageModel? getStageById(int id) {
    try {
      return LocalStorage.stages.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    await LocalStorage.setStages([]);
  }
}

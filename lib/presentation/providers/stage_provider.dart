import 'package:flutter/foundation.dart';

import '../../data/repositories/stage_repository.dart';
import '../../domain/entities/stage_entity.dart';
import '../../domain/usecases/load_stages.dart';
import '../../domain/usecases/unlock_next_stage.dart';

class StageProvider extends ChangeNotifier {
  final StageRepository _repository;
  final UnlockNextStageUseCase _unlockUseCase;

  List<StageEntity> _stages = [];
  int _unlockedStageIndex = 1;
  bool _isLoading = true;
  String? _error;

  StageProvider({
    required StageRepository repository,
    required UnlockNextStageUseCase unlockUseCase,
  })  : _repository = repository,
        _unlockUseCase = unlockUseCase;

  List<StageEntity> get stages => _stages;
  int get unlockedStageIndex => _unlockedStageIndex;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final entities = await LoadStagesUseCase(repository: _repository).execute();
      _stages = entities;
      _unlockedStageIndex = _repository.getUnlockedStageIndex();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isStageUnlocked(int stageId) => stageId <= _unlockedStageIndex;

  bool isStageSpecial(int stageId) => _unlockUseCase.isSpecialStage(stageId);

  int livesForStage(int stageId) => _unlockUseCase.livesForStage(stageId);

  Future<void> markStageCompleted(int stageId, {int stars = 0}) async {
    await _repository.markStageCompleted(stageId, stars: stars);
    _unlockedStageIndex = _repository.getUnlockedStageIndex();
    notifyListeners();
  }

  /// Sum of stars earned across all completed stages.
  int getTotalStars() {
    var total = 0;
    for (final stage in _stages) {
      final progress = _repository.getStageProgress(stage.id);
      if (progress != null && progress.isCompleted) {
        total += progress.starsEarned;
      }
    }
    return total;
  }

  /// Sum of score/coins gained across all stages (every completed stage
  /// contributes its score to the total shown on the map).
  int getTotalScore() {
    var total = 0;
    for (final stage in _stages) {
      final progress = _repository.getStageProgress(stage.id);
      if (progress != null && progress.isCompleted) {
        total += progress.starsEarned;
      }
    }
    return total;
  }

  /// Stars earned on a single stage (0 when it has never been cleared).
  int getStarsForStage(int stageId) =>
      _repository.getStageProgress(stageId)?.starsEarned ?? 0;
}

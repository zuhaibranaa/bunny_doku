import 'dart:async';

import '../../data/repositories/stage_repository.dart';
import '../../domain/entities/stage_entity.dart';

/// Loads stages from the repository and converts to entities.
class LoadStagesUseCase {
  final StageRepository repository;

  LoadStagesUseCase({required this.repository});

  Future<List<StageEntity>> execute() async {
    await repository.initializeStages();
    final models = repository.getAllStages();
    return models
        .map((m) => StageEntity(
              id: m.id,
              unlockDate: m.unlockDate,
              difficulty: m.difficulty,
              isSpecial: m.isSpecial,
              regionGrid: m.regionGrid,
              starterBunnyRow: m.starterBunnyRow,
              starterBunnyCol: m.starterBunnyCol,
              solution: m.solution,
            ))
        .toList();
  }

  int getUnlockedStageIndex() => repository.getUnlockedStageIndex();
}

/// Determines unlock state and special-stage flags.
class UnlockNextStageUseCase {
  /// Whether [stageIndex] (1-based) is a special stage (1 life instead of 3).
  bool isSpecialStage(int stageIndex) =>
      stageIndex % 10 == 0;

  /// Lives for a given stage index.
  int livesForStage(int stageIndex) =>
      isSpecialStage(stageIndex) ? 1 : 3;

  /// Whether the next stage (current + 1) should be unlocked.
  bool shouldUnlockNext(int currentStageId, bool isCompleted) =>
      isCompleted;
}

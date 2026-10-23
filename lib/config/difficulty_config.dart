/// Board-size ramp for the bundled stage pack.
///
/// The pack holds 1000 stages. Each stage's size is random inside its band
/// (that is what `tool/generate_ramp.py` uses); the authoritative size is
/// always the stage's own `regionGrid`, this config only mirrors the design
/// ramp for UI copy and tests.
class DifficultyConfig {
  /// (last stage id, min board size, max board size)
  static const List<(int, int, int)> sizeBands = [
    (100, 5, 6),
    (300, 6, 7),
    (550, 7, 8),
    (800, 8, 9),
    (1000, 9, 10),
  ];

  /// Number of stages in the bundled pack.
  static const int stageCount = 1000;

  /// Smallest board size the game ever uses (3x3/4x4 are too small to host
  /// interesting puzzles once every board must have a unique solution).
  static const int minBoardSize = 5;

  /// Largest board size the game ever uses.
  static const int maxBoardSize = 10;

  /// Smallest board size used by [stageNumber].
  static int minGridSizeForStage(int stageNumber) {
    for (final (last, lo, _) in sizeBands) {
      if (stageNumber <= last) return lo;
    }
    return sizeBands.last.$2;
  }

  /// Largest board size used by [stageNumber].
  static int maxGridSizeForStage(int stageNumber) {
    for (final (last, _, hi) in sizeBands) {
      if (stageNumber <= last) return hi;
    }
    return sizeBands.last.$3;
  }

  /// Upper bound of the band — kept for callers that want a single number.
  static int gridSizeForStage(int stageNumber) =>
      maxGridSizeForStage(stageNumber);

  /// A solved board holds one bunny per region, and regionCount == board size.
  static int requiredBunniesForSize(int gridSize) => gridSize;

  static bool isSpecialForStage(int stageNumber) => stageNumber % 10 == 0;
}

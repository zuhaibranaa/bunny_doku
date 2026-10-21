/// Core constants for the puzzle grid and game rules.
/// Changing these requires regenerating all existing levels.
import '../../config/release_config.dart';

class AppConstants {
  static const int gridSize = 10; // 10 x 10
  static const int regionCount = 10; // 10 colors / regions
  static const int normalLives = 3;
  static const int specialLives = 1;

  /// Returns true if [stageIndex] (1-based) is a special stage.
  static bool isSpecialStage(int stageIndex) =>
      stageIndex % ReleaseConfig.specialStageInterval == 0;

  static int livesForStage(int stageIndex) =>
      isSpecialStage(stageIndex) ? specialLives : normalLives;
}

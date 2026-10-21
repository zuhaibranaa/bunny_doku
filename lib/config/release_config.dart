/// Release configuration for daily stage drops.
///
/// contentVersion is bumped when a new stage pack is published remotely.
/// pubspec.yaml version is only bumped for security / bug fix app updates.
class ReleaseConfig {
  /// Content version of the daily stage pack.
  /// Bump this whenever `assets/stages/stage_pack_v1.json` changes so installed
  /// clients reload the bundled pack instead of keeping a stale cache.
  static const int contentVersion = 5;

  /// How often (in days) new stages are released.
  static const int stageReleaseIntervalDays = 1;

  /// Every Nth stage (1-based) is a special stage with 1 life instead of 3.
  static const int specialStageInterval = 10;

  /// Base URL for remote stage pack JSON.
  /// Override via environment or Firebase Remote Config in production.
  static const String stagePackBaseUrl =
      'https://api.rabitdoku.example.com/stage-packs';

    /// If true, app prompts users to update only for security/bug fixes,
  /// never for new stages.
  static const bool stagesRequireAppUpdate = false;
}

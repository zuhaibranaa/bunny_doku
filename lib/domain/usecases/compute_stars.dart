/// Computes star rating (1-3) based on hearts remaining, time, and boosters used.
class ComputeStarsUseCase {
  /// Calculates stars for a completed stage.
  ///
  /// [heartsRemaining] - hearts left at completion
  /// [livesStart] - hearts at start (3 normal, 1 special)
  /// [timeSeconds] - time taken to complete
  /// [boostersUsed] - number of boosters used
  int execute({
    required int heartsRemaining,
    required int livesStart,
    required int timeSeconds,
    required int boostersUsed,
  }) {
    int stars = 1;

    // 3 stars: perfect or near-perfect
    if (heartsRemaining == livesStart && boostersUsed == 0 && timeSeconds < 60) {
      stars = 3;
    }
    // 2 stars: good performance
    else if (heartsRemaining >= livesStart - 1 && boostersUsed <= 1 && timeSeconds < 120) {
      stars = 2;
    }
    // 1 star: completed but used resources
    else if (heartsRemaining > 0) {
      stars = 1;
    }

    return stars.clamp(1, 3);
  }
}

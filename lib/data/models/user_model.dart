/// User model — stored in shared_preferences as JSON.
class UserModel {
  final String userId;
  int totalHearts;
  int totalStars;
  int totalCoins;
  int adTenureDay;
  DateTime lastInterstitialTs;
  bool isAdsRemoved;
  DateTime createdAt;
  DateTime lastLoginAt;

  /// Extra lives (refillable lives for playing stages).
  /// Max 5, min 0. Refills 1 every 5 minutes.
  int otherLives;
  /// Timestamp of last life refill.
  DateTime lastLifeRefillTs;

  UserModel({
    required this.userId,
    this.totalHearts = 5,
    this.totalStars = 0,
    this.totalCoins = 0,
    this.adTenureDay = 0,
    DateTime? lastInterstitialTs,
    this.isAdsRemoved = false,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    this.otherLives = 5,
    DateTime? lastLifeRefillTs,
  })  : lastInterstitialTs = lastInterstitialTs ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        lastLoginAt = lastLoginAt ?? DateTime.now(),
        lastLifeRefillTs = lastLifeRefillTs ?? DateTime.now();

  /// Days since first launch (used for ad tenure segmentation).
  int get daysSinceFirstLaunch =>
      DateTime.now().difference(createdAt).inDays;

  /// Whether interstitial ads should show based on tenure cooldown.
  bool shouldShowInterstitial(int currentStage) {
    if (isAdsRemoved) return false;
    if (currentStage < 10) return false; // AdConfig.interstitialStartStage

    final cooldown = _interstitialCooldownSeconds(adTenureDay);
    final sinceLast = DateTime.now().difference(lastInterstitialTs).inSeconds;
    return sinceLast >= cooldown;
  }

  int _interstitialCooldownSeconds(int tenureDays) {
    if (tenureDays < 2) return 120;
    if (tenureDays < 7) return 100;
    return 90;
  }

  void recordInterstitialShown() {
    lastInterstitialTs = DateTime.now();
  }

  /// Increment tenure day if a new day has passed since last login.
  void updateTenureIfNewDay() {
    final now = DateTime.now();
    if (now.difference(lastLoginAt).inDays >= 1) {
      adTenureDay = daysSinceFirstLaunch;
      lastLoginAt = now;
    }
  }

  // ============ Extra Lives System ============

  /// Refill extra lives based on elapsed time since last refill.
  /// 1 life every 5 minutes, max 5.
  void refillLives() {
    final now = DateTime.now();
    final diffMinutes = now.difference(lastLifeRefillTs).inMinutes;
    if (diffMinutes >= 5 && otherLives < 5) {
      final livesToAdd = (diffMinutes / 5).floor();
      otherLives = (otherLives + livesToAdd).clamp(0, 5);
      lastLifeRefillTs = now;
    }
  }

  /// Returns the number of seconds until the next life refill.
  int get secondsUntilNextRefill {
    if (otherLives >= 5) return 0;
    final now = DateTime.now();
    final nextRefill = lastLifeRefillTs.add(const Duration(minutes: 5));
    final diff = nextRefill.difference(now).inSeconds;
    return diff.clamp(0, 300);
  }

  /// Whether extra lives are available to play a stage.
  bool get hasExtraLives => otherLives > 0;

  /// Consume one extra life. Returns true if successful.
  bool consumeExtraLife() {
    if (otherLives <= 0) return false;
    otherLives -= 1;
    return true;
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'totalHearts': totalHearts,
        'totalStars': totalStars,
        'totalCoins': totalCoins,
        'adTenureDay': adTenureDay,
        'lastInterstitialTs': lastInterstitialTs.toIso8601String(),
        'isAdsRemoved': isAdsRemoved ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
        'lastLoginAt': lastLoginAt.toIso8601String(),
        'otherLives': otherLives,
        'lastLifeRefillTs': lastLifeRefillTs.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as String,
      totalHearts: json['totalHearts'] as int? ?? 5,
      totalStars: json['totalStars'] as int? ?? 0,
      totalCoins: json['totalCoins'] as int? ?? (json['totalStars'] as int? ?? 0),
      adTenureDay: json['adTenureDay'] as int? ?? 0,
      lastInterstitialTs: DateTime.parse(
        json['lastInterstitialTs'] as String? ?? DateTime.now().toIso8601String(),
      ),
      isAdsRemoved: (json['isAdsRemoved'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      lastLoginAt: DateTime.parse(
        json['lastLoginAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      otherLives: (json['otherLives'] as int? ?? 5).clamp(0, 5),
      lastLifeRefillTs: DateTime.parse(
        json['lastLifeRefillTs'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

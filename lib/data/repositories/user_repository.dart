import '../models/user_model.dart';
import '../storage/local_storage.dart';

/// Repository for user data (hearts, stars, tenure, ads removed).
class UserRepository {
  UserModel? _cachedUser;

  UserModel getOrCreateUser() {
    if (_cachedUser != null) return _cachedUser!;

    final existing = LocalStorage.user;
    if (existing != null) {
      _cachedUser = existing;
      return existing;
    }

    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    final user = UserModel(userId: userId);
    LocalStorage.setUserId(userId);
    LocalStorage.setUser(user);
    _cachedUser = user;
    return user;
  }

  UserModel? getCurrentUser() => _cachedUser ?? LocalStorage.user;

  Future<void> saveUser(UserModel user) async {
    _cachedUser = user;
    await LocalStorage.setUser(user);
  }

  Future<void> addHearts(int amount) async {
    final user = getOrCreateUser();
    user.totalHearts += amount;
    await saveUser(user);
  }

  Future<void> consumeHeart() async {
    final user = getOrCreateUser();
    if (user.totalHearts <= 0) throw StateError('No hearts remaining');
    user.totalHearts -= 1;
    await saveUser(user);
  }

  Future<void> addStars(int amount) async {
    final user = getOrCreateUser();
    user.totalStars += amount;
    await saveUser(user);
  }

  Future<void> addCoins(int amount) async {
    final user = getOrCreateUser();
    user.totalCoins += amount;
    await saveUser(user);
  }

  /// Spends coins. Returns false (and changes nothing) when the balance is
  /// too low, so callers can check the result before granting the purchase.
  Future<bool> spendCoins(int amount) async {
    final user = getOrCreateUser();
    if (user.totalCoins < amount) return false;
    user.totalCoins -= amount;
    await saveUser(user);
    return true;
  }

  Future<void> removeAds() async {
    final user = getOrCreateUser();
    user.isAdsRemoved = true;
    await LocalStorage.setIsAdsRemoved(true);
    await saveUser(user);
  }

  // ============ Extra Lives Methods ============

  /// Refill extra lives based on elapsed time since last refill.
  /// Call this on app launch and before each stage play.
  void refillLives() {
    final user = getOrCreateUser();
    user.refillLives();
    saveUser(user);
  }

  /// Returns the current extra lives count (0-5).
  int getExtraLives() {
    final user = getOrCreateUser();
    user.refillLives();
    saveUser(user);
    return user.otherLives;
  }

  /// Returns seconds until next life refill (0 if at max).
  int getSecondsUntilNextRefill() {
    final user = getOrCreateUser();
    return user.secondsUntilNextRefill;
  }

  /// Whether extra lives are available to play a stage.
  bool hasExtraLives() {
    final user = getOrCreateUser();
    user.refillLives();
    return user.hasExtraLives;
  }

  /// Add [amount] extra lives (rewarded-ad revive / booster purchase).
  /// Capped at the max of 5.
  void addExtraLife(int amount) {
    final user = getOrCreateUser();
    user.otherLives = (user.otherLives + amount).clamp(0, 5);
    saveUser(user);
  }

  /// Consume one extra life when a stage is failed.
  /// Returns true if a life was consumed, false if none available.
  bool consumeExtraLife() {
    final user = getOrCreateUser();
    user.refillLives();
    final result = user.consumeExtraLife();
    saveUser(user);
    return result;
  }
}

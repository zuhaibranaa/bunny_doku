/// Domain entity for the user.
class UserEntity {
  final String userId;
  int totalHearts;
  int totalStars;
  int adTenureDay;
  DateTime lastInterstitialTs;
  bool isAdsRemoved;

  UserEntity({
    required this.userId,
    this.totalHearts = 5,
    this.totalStars = 0,
    this.adTenureDay = 0,
    required this.lastInterstitialTs,
    this.isAdsRemoved = false,
  });
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../data/repositories/user_repository.dart';

bool get _isMobile => Platform.isAndroid || Platform.isIOS;

class AdProvider extends ChangeNotifier {
  final UserRepository _userRepo;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  BannerAd? _bannerAd;

  bool _isInterstitialLoaded = false;
  bool _isRewardedLoaded = false;
  bool _isBannerLoaded = false;
  String? _error;

  AdProvider([UserRepository? userRepo]) : _userRepo = userRepo ?? UserRepository();

  bool get isInterstitialLoaded => _isInterstitialLoaded;
  bool get isRewardedLoaded => _isRewardedLoaded;
  bool get isBannerLoaded => _isBannerLoaded;
  String? get error => _error;

  void loadBannerAd() {
    if (!_isMobile) return;
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _isBannerLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, err) {
          _isBannerLoaded = false;
          _error = 'Banner failed: $err';
          ad.dispose();
          notifyListeners();
        },
      ),
    );
    _bannerAd!.load();
  }

  void loadInterstitialAd() {
    if (!_isMobile) return;
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (err) {
          _isInterstitialLoaded = false;
          _error = 'Interstitial failed: $err';
          notifyListeners();
        },
      ),
    );
  }

  void loadRewardedAd() {
    if (!_isMobile) return;
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (err) {
          _isRewardedLoaded = false;
          _error = 'Rewarded failed: $err';
          notifyListeners();
        },
      ),
    );
  }

  Future<bool> showInterstitial(int currentStage) async {
    if (!_isMobile) return false;
    final user = _userRepo.getCurrentUser();
    if (user == null) return false;

    user.updateTenureIfNewDay();

    if (!user.shouldShowInterstitial(currentStage)) {
      return false;
    }

    if (_interstitialAd == null || !_isInterstitialLoaded) {
      loadInterstitialAd();
      return false;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        user.recordInterstitialShown();
        _userRepo.saveUser(user);
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialLoaded = false;
        loadInterstitialAd();
        notifyListeners();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialLoaded = false;
        notifyListeners();
      },
    );

    await _interstitialAd!.show();
    return true;
  }

  Future<bool> showRewardedAd(OnUserEarnedRewardCallback onReward) async {
    if (!_isMobile) return false;
    if (_rewardedAd == null || !_isRewardedLoaded) {
      loadRewardedAd();
      return false;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedLoaded = false;
        loadRewardedAd();
        notifyListeners();
      },
    );

    await _rewardedAd!.show(onUserEarnedReward: onReward);
    return true;
  }

  void disposeAds() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _bannerAd?.dispose();
  }
}

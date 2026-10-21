import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../config/booster_config.dart';
import '../../data/repositories/booster_repository.dart';
import '../../data/repositories/user_repository.dart';

const String removeAdsProductId = 'remove_ads';

bool get _isMobile => Platform.isAndroid || Platform.isIOS;

class IAPProvider extends ChangeNotifier {
  final BoosterRepository _boosterRepo;
  final UserRepository _userRepo;

  final InAppPurchase _iap = InAppPurchase.instance;

  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  bool _isAvailable = false;
  String? _error;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  IAPProvider({
    required BoosterRepository boosterRepo,
    required UserRepository userRepo,
  })  : _boosterRepo = boosterRepo,
        _userRepo = userRepo;

  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;
  String? get error => _error;

  Future<void> init() async {
    if (!_isMobile) {
      _isAvailable = false;
      _error = 'In-app purchases not available on desktop';
      notifyListeners();
      return;
    }

    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      _error = 'In-app purchases not available on this platform';
      notifyListeners();
      return;
    }

    final ids = <String>{
      for (final b in BoosterConfig.allBoosters) b['id'] as String,
      removeAdsProductId,
    };

    final response = await _iap.queryProductDetails(ids);
    if (response.notFoundIDs.isNotEmpty) {
      _error = 'Products not found: ${response.notFoundIDs}';
    }
    _products = response.productDetails.toList();
    notifyListeners();

    _subscription = _iap.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        _handlePurchase(purchase);
      }
    });
  }

  void _handlePurchase(PurchaseDetails purchase) {
    _purchases.add(purchase);
    if (purchase.status == PurchaseStatus.purchased) {
      _completePurchase(purchase);
    }
    notifyListeners();
  }

  Future<void> _completePurchase(PurchaseDetails purchase) async {
    if (purchase.productID == removeAdsProductId) {
      await _userRepo.removeAds();
    } else {
      await _boosterRepo.addBooster(purchase.productID, 1);
    }
  }

  Future<void> buyProduct(String productId) async {
    if (!_isMobile || !_isAvailable) {
      _error = 'IAP not available';
      notifyListeners();
      return;
    }

    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product $productId not found'),
    );
    await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  Future<void> buyBooster(String boosterId) async {
    await buyProduct(boosterId);
  }

  Future<void> buyRemoveAds() async {
    await buyProduct(removeAdsProductId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

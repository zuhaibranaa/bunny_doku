import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../config/booster_config.dart';
import '../../config/coin_config.dart';
import '../../data/repositories/user_repository.dart';

bool get _isMobile => Platform.isAndroid || Platform.isIOS;

class IAPProvider extends ChangeNotifier {
  final UserRepository _userRepo;

  final InAppPurchase _iap = InAppPurchase.instance;

  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  bool _isAvailable = false;
  String? _error;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  IAPProvider({required UserRepository userRepo}) : _userRepo = userRepo;

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
      for (final p in CoinConfig.packages) p.id,
      removeAdsProductId,
      'coins_pack', // legacy alias, harmless if missing
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
      final pack = CoinConfig.packageForProduct(purchase.productID);
      if (pack != null) {
        await _userRepo.addCoins(pack.coins);
      }
    }
    // Consumables must be acknowledged so they can be purchased again.
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
    notifyListeners();
  }

  /// Localised store price for a product, falling back to [fallback].
  String priceFor(String productId, String fallback) {
    for (final p in _products) {
      if (p.id == productId) return p.price;
    }
    return fallback;
  }

  /// Buys a coin package. Returns true when the purchase flow started.
  Future<bool> buyCoinPackage(CoinPackage pack) async {
    if (!_isMobile || !_isAvailable) {
      return _devGrantCoins(pack);
    }

    ProductDetails? product;
    for (final p in _products) {
      if (p.id == pack.id) product = p;
    }
    if (product == null) {
      // Product is not configured in the store yet — in debug builds allow
      // testing the flow without a real transaction.
      return _devGrantCoins(pack);
    }

    try {
      final started = await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
        autoConsume: true,
      );
      return started;
    } catch (e) {
      _error = 'Purchase failed: $e';
      notifyListeners();
      return false;
    }
  }

  /// Debug-only fallback so the coin flow is testable before the store
  /// products exist. Never grants coins in release builds.
  Future<bool> _devGrantCoins(CoinPackage pack) async {
    if (!kDebugMode) {
      _error = 'Purchases are not configured yet.';
      notifyListeners();
      return false;
    }
    await _userRepo.addCoins(pack.coins);
    notifyListeners();
    return true;
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
    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
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

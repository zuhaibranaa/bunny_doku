/// Coin packages sold for real money through in-app purchases.
///
/// Each package maps to a Google Play / App Store consumable product id.
class CoinPackage {
  const CoinPackage({
    required this.id,
    required this.coins,
    required this.priceUsd,
  });

  /// Store product id (must exist in Play Console / App Store Connect).
  final String id;

  /// Coins granted when the purchase completes.
  final int coins;

  /// Display price. The store's localised price is preferred when available.
  final double priceUsd;
}

class CoinConfig {
  static const List<CoinPackage> packages = [
    CoinPackage(id: 'coins_100', coins: 100, priceUsd: 0.99),
    CoinPackage(id: 'coins_550', coins: 550, priceUsd: 4.99),
    CoinPackage(id: 'coins_1200', coins: 1200, priceUsd: 9.99),
  ];

  /// Finds the package for a purchased product id.
  static CoinPackage? packageForProduct(String productId) {
    for (final p in packages) {
      if (p.id == productId) return p;
    }
    return null;
  }
}

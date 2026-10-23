import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/coin_config.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/entities/booster_entity.dart';
import '../providers/ad_provider.dart';
import '../providers/booster_provider.dart';
import '../providers/iap_provider.dart';
import '../widgets/rabbit_icon.dart';
import 'game_screen.dart';

/// Shop screen.
///
/// - Coin packages bought with real money (IAP).
/// - Boosters bought with coins or by watching a rewarded ad.
class BoosterShopScreen extends StatefulWidget {
  final List<BoosterEntity> boosters;
  final VoidCallback onBuyRemoveAds;
  final bool isAdsRemoved;

  const BoosterShopScreen({
    super.key,
    required this.boosters,
    required this.onBuyRemoveAds,
    required this.isAdsRemoved,
  });

  @override
  State<BoosterShopScreen> createState() => _BoosterShopScreenState();
}

class _BoosterShopScreenState extends State<BoosterShopScreen> {
  /// Booster / package currently waiting on an ad or purchase so the buttons
  /// can show a spinner and can't be tapped twice.
  String? _pendingId;

  @override
  void initState() {
    super.initState();
    // Make sure a reward is ready by the time the player taps "Ad".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ads = context.read<AdProvider>();
      if (!ads.isRewardedLoaded) ads.loadRewardedAd();
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ));
  }

  /// Buys one booster with coins (or an ad when [withAd] is true).
  Future<void> _buyBooster(BoosterEntity b, bool withAd) async {
    if (_pendingId != null) return;
    final boosterProvider = context.read<BoosterProvider>();
    final userRepo = context.read<UserRepository>();

    if (withAd) {
      setState(() => _pendingId = b.id);
      bool shown = false;
      try {
        shown = await boosterProvider.buyBoosterWithAd(b.id);
      } finally {
        if (mounted) setState(() => _pendingId = null);
      }
      _snack(shown
          ? '+1 ${b.name} earned from ad'
          : 'Ad not ready — try again in a moment.');
      return;
    }

    // Coin purchase.
    setState(() => _pendingId = b.id);
    try {
      final balance = userRepo.getCurrentUser()?.totalCoins ?? 0;
      if (balance < b.coinPrice) {
        _snack('Not enough coins — ${b.coinPrice} needed.');
        return;
      }
      final paid = await userRepo.spendCoins(b.coinPrice);
      if (!paid) {
        _snack('Not enough coins — ${b.coinPrice} needed.');
        return;
      }
      await boosterProvider.addQuantity(b.id, 1);
      _snack('+1 ${b.name} for ${b.coinPrice} coins');
    } finally {
      if (mounted) setState(() => _pendingId = null);
    }
  }

  /// Buys a coin package with real money.
  Future<void> _buyCoins(CoinPackage pack) async {
    if (_pendingId != null) return;
    final iap = context.read<IAPProvider>();
    setState(() => _pendingId = pack.id);
    bool ok = false;
    try {
      ok = await iap.buyCoinPackage(pack);
    } finally {
      if (mounted) setState(() => _pendingId = null);
    }
    _snack(ok
        ? '+${pack.coins} coins added'
        : 'Purchase unavailable right now.');
  }

  @override
  Widget build(BuildContext context) {
    final boosters = widget.boosters;
    final iap = context.watch<IAPProvider>();
    // watch so the header balance refreshes after purchases
    final balance =
        context.watch<UserRepository>().getCurrentUser()?.totalCoins ?? 0;

    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Text('Booster Shop',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const Spacer(),
                  const Icon(Icons.monetization_on, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('$balance',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                children: [
                  // ---- Coins ------------------------------------------------
                  const _SectionTitle('Coins'),
                  ...CoinConfig.packages.map((pack) {
                    final pending = _pendingId == pack.id;
                    final price = iap.priceFor(
                      pack.id,
                      '\$${pack.priceUsd.toStringAsFixed(2)}',
                    );
                    return _ShopCard(
                      leading: const Icon(Icons.monetization_on,
                          color: Colors.amber, size: 32),
                      title: '${pack.coins} Coins',
                      subtitle: 'Top up your balance',
                      action: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _pendingId != null
                            ? null
                            : () => _buyCoins(pack),
                        child: pending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(price),
                      ),
                    );
                  }),

                  // ---- Boosters --------------------------------------------
                  const _SectionTitle('Boosters'),
                  ...boosters.map((b) {
                    final owned = context
                        .watch<BoosterProvider>()
                        .getQuantity(b.id);
                    final pending = _pendingId == b.id;
                    return _ShopCard(
                      leading: _boosterIcon(b.id),
                      title: b.name,
                      subtitle: '${b.description}\nOwned: $owned',
                      action: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (b.priceAd)
                            OutlinedButton.icon(
                              onPressed: _pendingId != null
                                  ? null
                                  : () => _buyBooster(b, true),
                              icon: pending
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.play_circle, size: 16),
                              label: const Text('Ad'),
                            ),
                          const SizedBox(width: 6),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kOrange,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _pendingId != null
                                ? null
                                : () => _buyBooster(b, false),
                            icon: const Icon(Icons.monetization_on, size: 16),
                            label: Text('${b.coinPrice}'),
                          ),
                        ],
                      ),
                    );
                  }),

                  if (!widget.isAdsRemoved) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: widget.onBuyRemoveAds,
                        icon: const Icon(Icons.block, color: Colors.white70),
                        label: const Text('Remove Ads',
                            style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boosterIcon(String id) {
    if (id == 'booster_hint') {
      return const Icon(Icons.lightbulb, color: Colors.amber, size: 32);
    }
    if (id == 'booster_extra_life') {
      return const Icon(Icons.favorite, color: Colors.redAccent, size: 32);
    }
    return const RabbitIcon(size: 28);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: Colors.white.withValues(alpha: 0.08),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              action,
            ],
          ),
        ),
      ),
    );
  }
}

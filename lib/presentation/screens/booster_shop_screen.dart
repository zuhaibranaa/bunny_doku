import 'package:flutter/material.dart';

import '../../domain/entities/booster_entity.dart';
import '../widgets/rabbit_icon.dart';
import 'game_screen.dart';

/// Shop screen where players buy boosters with money or ads.
class BoosterShopScreen extends StatefulWidget {
  final List<BoosterEntity> boosters;
  final void Function(String id, bool withAd) onBuyBooster;
  final void Function() onBuyRemoveAds;
  final bool isAdsRemoved;
  final int coinBalance;
  final Future<bool> Function(String id)? onBuyWithCoins;

  BoosterShopScreen({
    super.key,
    required this.boosters,
    required this.onBuyBooster,
    required this.onBuyRemoveAds,
    required this.isAdsRemoved,
    this.coinBalance = 0,
    this.onBuyWithCoins,
  });

  @override
  State<BoosterShopScreen> createState() => _BoosterShopScreenState();
}

class _BoosterShopScreenState extends State<BoosterShopScreen> {
  /// Live coin balance — kept in sync after every coin purchase so the
  /// header and the dialog never show a stale amount.
  late int _balance = widget.coinBalance;

  @override
  Widget build(BuildContext context) {
    final boosters = widget.boosters;
    final isAdsRemoved = widget.isAdsRemoved;
    final onBuyBooster = widget.onBuyBooster;
    final onBuyRemoveAds = widget.onBuyRemoveAds;
    final onBuyWithCoins = widget.onBuyWithCoins;

    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        title: const Text('Booster Shop'),
        backgroundColor: kMauve,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 4),
                Text('$_balance'),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          if (onBuyWithCoins != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => _showCoinBuyDialog(context),
                icon: const Icon(Icons.monetization_on),
                label: const Text('Buy 3 Boosters of Any Choice for 100 Coins'),
              ),
            ),
          if (!isAdsRemoved)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                onPressed: onBuyRemoveAds,
                icon: const Icon(Icons.info),
                label: const Text('Remove Ads'),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: boosters.length,
              itemBuilder: (context, index) {
                final b = boosters[index];
                return ListTile(
                  leading: _boosterIcon(b.id),
                  title: Text(b.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(b.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (b.priceAd)
                        OutlinedButton.icon(
                          onPressed: () => onBuyBooster(b.id, true),
                          icon: const Icon(Icons.play_circle, size: 16),
                          label: const Text('Ad'),
                        ),
                      ElevatedButton.icon(
                        onPressed: () => onBuyBooster(b.id, false),
                        icon: const Icon(Icons.attach_money, size: 16),
                        label: Text('\$${b.priceUsd.toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCoinBuyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kCream,
        title: const Text('Buy 3 Boosters for 100 Coins', style: TextStyle(color: Colors.white)),
        contentTextStyle: const TextStyle(color: Colors.white),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Balance: $_balance coins', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
            for (final b in widget.boosters)
              ListTile(
                leading: _boosterIcon(b.id),
                title: Text(b.name, style: const TextStyle(color: Colors.white)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white),
                  onPressed: _balance >= 100
                      ? () async {
                          final bought = await widget.onBuyWithCoins?.call(b.id);
                          if (!mounted) return;
                          if (bought == true) {
                            setState(() => _balance -= 100);
                          }
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        }
                      : null,
                  child: const Text('Choose'),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: kGold)),
          ),
        ],
      ),
    );
  }
  Widget _boosterIcon(String id) {
    if (id.contains('hint')) {
      return const Icon(Icons.lightbulb_outline, color: Color(0xFF38A169), size: 28);
    }
    if (id.contains('reveal')) {
      return const Icon(Icons.remove_red_eye, color: Colors.teal, size: 28);
    }
    if (id.contains('extra_life')) {
      return const Icon(Icons.favorite, color: Colors.pink, size: 28);
    }
    return const RabbitIcon(size: 28);
  }
}

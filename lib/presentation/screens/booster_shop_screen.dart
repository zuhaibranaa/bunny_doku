import 'package:flutter/material.dart';

import '../../domain/entities/booster_entity.dart';
import '../widgets/rabbit_icon.dart';

/// Shop screen where players buy boosters with money or ads.
class BoosterShopScreen extends StatelessWidget {
  final List<BoosterEntity> boosters;
  final void Function(String id, bool withAd) onBuyBooster;
  final void Function() onBuyRemoveAds;
  final bool isAdsRemoved;
  final int coinBalance;
  final void Function(String id)? onBuyWithCoins;

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booster Shop'),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 4),
                Text('$coinBalance'),
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
        title: const Text('Buy 3 Boosters for 100 Coins'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Balance: $coinBalance coins'),
            const SizedBox(height: 12),
            for (final b in boosters)
              ListTile(
                leading: _BoosterExt(this)._boosterIcon(b.id),
                title: Text(b.name),
                trailing: ElevatedButton(
                  onPressed: coinBalance >= 100
                      ? () {
                          onBuyWithCoins?.call(b.id);
                          Navigator.pop(dialogContext);
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
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

extension _BoosterExt on BoosterShopScreen {
  Widget _boosterIcon(String id) {
    if (id.contains('hint') || id.contains('reveal')) {
      return const Icon(Icons.lightbulb_outline, color: Color(0xFF8B5CF6), size: 28);
    }
    if (id.contains('undo')) {
      return const Icon(Icons.undo, color: Color(0xFF5E72EB), size: 28);
    }
    if (id.contains('extra_life')) {
      return const Icon(Icons.favorite, color: Colors.pink, size: 28);
    }
    return const RabbitIcon(size: 28);
  }
}

import 'package:flutter/material.dart';

/// Booster button in the shop / game UI.
class BoosterButton extends StatelessWidget {
  final String boosterId;
  final String name;
  final int quantity;
  final int coinPrice;
  final bool canBuyWithAd;
  final VoidCallback onBuyWithCoins;
  final VoidCallback onBuyWithAd;
  final VoidCallback? onUse;

  const BoosterButton({
    super.key,
    required this.boosterId,
    required this.name,
    required this.quantity,
    required this.coinPrice,
    required this.canBuyWithAd,
    required this.onBuyWithCoins,
    required this.onBuyWithAd,
    this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    final canUse = quantity > 0 && onUse != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (canUse)
              ElevatedButton.icon(
                onPressed: onUse,
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('Use'),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (canBuyWithAd)
                    OutlinedButton.icon(
                      onPressed: onBuyWithAd,
                      icon: const Icon(Icons.play_circle, size: 16),
                      label: const Text('Ad'),
                    ),
                  ElevatedButton.icon(
                    onPressed: onBuyWithCoins,
                    icon: const Icon(Icons.monetization_on, size: 16),
                    label: Text('$coinPrice'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text('Owned: $quantity', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

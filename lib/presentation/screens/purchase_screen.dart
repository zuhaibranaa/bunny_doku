import 'package:flutter/material.dart';

/// Purchase confirmation screen for IAP.
class PurchaseScreen extends StatelessWidget {
  final String productId;
  final String productName;
  final double price;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const PurchaseScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.price,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.attach_money, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Purchase $productName',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${price.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, color: Colors.green.shade700),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onConfirm,
                    child: const Text('Buy'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../domain/entities/stage_entity.dart';
import 'game_screen.dart';

/// Popup shown when tapping a stage node on the map.
class StagePopup extends StatelessWidget {
  final StageEntity stage;
  final int stars;
  final VoidCallback onPlay;
  final VoidCallback onClose;

  const StagePopup({
    super.key,
    required this.stage,
    required this.stars,
    required this.onPlay,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kCream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Stage ${stage.id}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, color: Colors.orange.shade400),
                const SizedBox(width: 8),
                Text(
                  stage.isSpecialStage ? 'SPECIAL - 1 Life' : 'Normal - 3 Lives',
                  style: TextStyle(
                    color: stage.isSpecialStage
                        ? Colors.orange.shade400
                        : kGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (stars > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    size: 26,
                    color: i < stars ? Colors.amber : Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 26),
                const SizedBox(width: 6),
                Text(
                  // Special stages always pay a flat 5-coin reward.
                  stage.isSpecialStage ? '+5 coins' : '+$stars coins',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                    onPressed: onClose,
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kOrange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onPlay,
                    child: const Text('Play'),
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

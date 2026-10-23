import 'package:flutter/material.dart';

/// A stage node on the Candy Crush map.
/// States: locked, available, completed.
class StageNode extends StatelessWidget {
  final int stageId;
  final bool isUnlocked;
  final bool isCompleted;
  final int stars;
  final bool isSpecial;
  final VoidCallback? onTap;

  const StageNode({
    super.key,
    required this.stageId,
    required this.isUnlocked,
    required this.isCompleted,
    this.stars = 0,
    required this.isSpecial,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color fillColor;
    IconData icon;
    Color iconColor;

    if (isCompleted) {
      fillColor = Colors.green.shade400;
      icon = Icons.check_circle;
      iconColor = Colors.white;
    } else if (isUnlocked) {
      fillColor = isSpecial ? Colors.red.shade700 : Colors.purple.shade400;
      icon = Icons.play_circle;
      iconColor = Colors.white;
    } else {
      fillColor = Colors.grey.shade400;
      icon = Icons.lock;
      iconColor = Colors.white70;
    }

    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: fillColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: isCompleted
                  ? Border.all(color: Colors.amber, width: 4)
                  : Border.all(
                      color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$stageId',
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Icon(icon, color: iconColor, size: 20),
              ],
            ),
          ),
          // Stars actually earned on this stage (only once it is cleared).
          if (isCompleted && stars > 0) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Icon(
                  i < stars ? Icons.star : Icons.star_border,
                  size: 12,
                  color: i < stars ? Colors.amber : Colors.white70,
                  shadows: const [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
          // Danger / skull warning for hard special levels.
          if (isSpecial && !isCompleted) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 10,
                  color: Colors.deepOrange,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

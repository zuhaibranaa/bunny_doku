import 'package:flutter/material.dart';

import 'rabbit_icon.dart';
import 'x_mark.dart';

/// A single cell in the 10x10 game grid (Meowdoku style).
///
/// Cells are solid region.*bunny here",
/// a red X marks a cell where a wrong placement was attempted, and a cute
/// white bunny shows a placed or starter) bunny. Pop / shake / flash animations are
/// driven by the parent via keyed TweenAnimationBuilders.
class GridCell extends StatelessWidget {
  final int row;
  final int col;
  final int regionId;
  final bool hasBunny; // player-placed (or placed or starter) bunny
  final bool isStarter;
  final bool hasXMark;
  final bool isWrongMarked; // auto red X after a wrong placement attempt
  final Color regionColor;
  final bool isHinted; // gold pulse highlight from the Hint booster

  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  const GridCell({
    super.key,
    required this.row,
    required this.col,
    required this.regionId,
    required this.hasBunny,
    required this.isStarter,
    required this.hasXMark,
    this.isWrongMarked = false,
    required this.regionColor,
    this.isHinted = false,
    required this.onTap,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        decoration: BoxDecoration(
          color: regionColor,
          border: Border.all(
            color: isStarter ? const Color(0xFFD4AF37) : Colors.white,
            width: isStarter ? 3 : 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (hasBunny)
              TweenAnimationBuilder<double>(
                key: ValueKey('bunny-$row-$col'),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                builder: (_, value, __) => Transform.scale(
                  scale: value,
                  child: const RabbitIcon(size: 64),
                ),
              )
            else if (isWrongMarked)
              TweenAnimationBuilder<double>(
                key: ValueKey('wrong-$row-$col'),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                builder: (_, value, __) => Transform.scale(
                  scale: value,
                  child: const BoldX(
                    size: 32,
                    color: Color(0xFFE53935),
                  ),
                ),
              )
            else if (hasXMark)
              TweenAnimationBuilder<double>(
                key: ValueKey('xmark-$row-$col'),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                builder: (_, value, __) => Transform.scale(
                  scale: value,
                  child: const BoldX(
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
            if (isHinted)
              Container(
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

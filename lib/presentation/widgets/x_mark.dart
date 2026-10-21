import 'package:flutter/material.dart';

/// A thick, hand-drawn style X mark (two crossed strokes with rounded caps).
///
/// Much bolder than the Material `Icons.close` glyph so it reads clearly on
/// the colored grid cells at a glance. Includes a faint drop stroke so the
/// white mark stays visible even on pale region colors.
class BoldX extends StatelessWidget {
  const BoldX({
    super.key,
    this.size = 30,
    this.color = Colors.white,
    this.strokeWidthRatio = 0.18,
  });

  final double size;
  final Color color;

  /// Stroke thickness as a fraction of [size] (0.18 ≈ twice the Material icon).
  final double strokeWidthRatio;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: XMarkPainter(
        color: color,
        strokeWidth: size * strokeWidthRatio,
      ),
    );
  }
}

/// Paints the X inside a 24x24 logical box (scaled to the requested size).
class XMarkPainter extends CustomPainter {
  XMarkPainter({
    this.color = Colors.white,
    this.strokeWidth = 5.4,
  });

  final Color color;

  /// Stroke thickness in logical pixels at the rendered [CustomPaint] size.
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.save();
    canvas.scale(s, s);

    final main = Paint()
      ..color = color
      ..strokeWidth = strokeWidth / s
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Soft dark backing so the mark pops on light-colored cells.
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..strokeWidth = (strokeWidth + 2.0) / s
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const a1 = Offset(5.4, 5.4);
    const b1 = Offset(18.6, 18.6);
    const a2 = Offset(18.6, 5.4);
    const b2 = Offset(5.4, 18.6);

    canvas.drawLine(a1, b1, shadow);
    canvas.drawLine(a2, b2, shadow);
    canvas.drawLine(a1, b1, main);
    canvas.drawLine(a2, b2, main);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant XMarkPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

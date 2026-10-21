import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'rabbit_icon.dart';

/// Infinitely looping, always-on animated meadow background for the stage
/// map: drifting clouds, birds, rolling green hills, swaying grass,
/// fluttering butterflies and a cute white rabbit hopping through the
/// greenery. There are no controls — it simply never stops.
class MapBackground extends StatefulWidget {
  const MapBackground({super.key});

  @override
  State<MapBackground> createState() => _MapBackgroundState();
}

class _MapBackgroundState extends State<MapBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          painter: _MeadowPainter(_controller.value),
          willChange: true,
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _MeadowPainter extends CustomPainter {
  _MeadowPainter(this.t);

  final double t; // 0..1 loop progress

  static const _skyTop = Color(0xFFBDE8FF);
  static const _skyBottom = Color(0xFFEAF7D9);
  static const _hillFar = Color(0xFFCBE8A6);
  static const _hillMid = Color(0xFFA9DB7E);
  static const _hillNear = Color(0xFF8CCB5B);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w == 0 || h == 0) return;

    _paintSky(canvas, size);
    _paintSun(canvas, size);
    _paintClouds(canvas, size);
    _paintBirds(canvas, size);

    final farY = h * 0.55;
    final midY = h * 0.66;
    final nearY = h * 0.80;

    _paintHill(canvas, w, farY, h * 0.06, _hillFar, 0.15);
    _paintHill(canvas, w, midY, h * 0.08, _hillMid, 0.35);
    _paintTrees(canvas, w, midY);
    _paintHill(canvas, w, nearY, h * 0.07, _hillNear, 0.7);
    _paintGrassDetails(canvas, w, h, nearY);
    _paintRabbit(canvas, w, h, nearY);
    _paintButterflies(canvas, w, h, nearY);
  }

  void _paintSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_skyTop, _skyBottom],
        ).createShader(rect),
    );
  }

  void _paintSun(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.82, size.height * 0.12);
    canvas.drawCircle(
      center,
      size.height * 0.14,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.55),
            Colors.amber.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: size.height * 0.14)),
    );
    canvas.drawCircle(
      center,
      size.height * 0.055,
      Paint()..color = const Color(0xFFFFE082),
    );
  }

  void _paintClouds(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.92);
    for (int i = 0; i < 3; i++) {
      final speed = 0.012 + i * 0.006;
      final x = ((t * speed + i * 0.37) % 1.2 - 0.1) * w;
      final y = h * (0.08 + i * 0.07);
      final s = h * (0.035 + i * 0.008);
      canvas.drawCircle(Offset(x, y), s, cloudPaint);
      canvas.drawCircle(Offset(x + s * 1.1, y - s * 0.35), s * 1.25, cloudPaint);
      canvas.drawCircle(Offset(x + s * 2.3, y), s * 0.9, cloudPaint);
    }
  }

  void _paintBirds(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final birdPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF6D5C5C).withValues(alpha: 0.6);
    for (int i = 0; i < 2; i++) {
      final x = ((t * (0.02 + i * 0.01) + i * 0.5) % 1.3 - 0.15) * w;
      final y = h * (0.10 + i * 0.06) + math.sin(t * 12 + i) * 3;
      final s = h * 0.012;
      final path = Path()
        ..moveTo(x - s, y)
        ..quadraticBezierTo(x - s * 0.5, y - s, x, y)
        ..quadraticBezierTo(x + s * 0.5, y - s, x + s, y);
      canvas.drawPath(path, birdPaint);
    }
  }

  void _paintHill(
    Canvas canvas,
    double w,
    double baseY,
    double amp,
    Color color,
    double phase,
  ) {
    final path = Path()..moveTo(0, baseY);
    const steps = 24;
    for (int i = 0; i <= steps; i++) {
      final x = w * i / steps;
      final y = baseY +
          math.sin((i / steps) * math.pi * 2 + phase + t * math.pi * 2 * 0.15) *
              amp;
      path.lineTo(x, y);
    }
    path
      ..lineTo(w, baseY + amp * 6)
      ..lineTo(0, baseY + amp * 6)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _paintTrees(Canvas canvas, double w, double midY) {
    final trunk = Paint()..color = const Color(0xFF8D6E63);
    final leaves = Paint()..color = const Color(0xFF6DBE45);
    for (int i = 0; i < 4; i++) {
      final baseX = ((i * 0.26 + t * 0.008) % 1.2 - 0.1) * w;
      final treeH = 26.0 + (i % 2) * 10;
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset(baseX, midY - treeH / 2 + 4), width: 5, height: treeH),
        trunk,
      );
      canvas.drawCircle(Offset(baseX, midY - treeH + 2), 16, leaves);
      canvas.drawCircle(Offset(baseX - 11, midY - treeH + 9), 11, leaves);
      canvas.drawCircle(Offset(baseX + 11, midY - treeH + 9), 11, leaves);
    }
  }

  void _paintGrassDetails(Canvas canvas, double w, double h, double nearY) {
    // Swaying grass tufts + flowers along the near hill.
    final grass = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF5FA33C);
    final flowerColors = [
      const Color(0xFFFF8FB1),
      Colors.white,
      const Color(0xFFFFD54F),
    ];
    for (int i = 0; i < 26; i++) {
      final x = ((i * 0.041 + t * 0.004) % 1.05) * w;
      final y = nearY + h * 0.045 + math.sin(i * 1.7) * 6;
      final sway = math.sin(t * math.pi * 8 + i) * 2.5;
      canvas.drawLine(Offset(x, y), Offset(x + sway, y - 9), grass);
      if (i % 3 == 0) {
        canvas.drawCircle(
          Offset(x + sway, y - 11),
          3,
          Paint()..color = flowerColors[i % flowerColors.length],
        );
      }
    }
  }

  void _paintRabbit(Canvas canvas, double w, double h, double nearY) {
    // Rabbit hops across the meadow, then takes a break off-screen.
    final p = (t * 1.35) % 1.35 - 0.18; // -0.18 .. 1.17, gap after each pass
    if (p < 0 || p > 1) return;

    final x = -40.0 + p * (w + 80);
    final groundY = nearY + h * 0.075;

    // 8 hops across the screen.
    final hopPhase = p * 8;
    final airborne = (math.sin(hopPhase * math.pi)).abs();
    final airY = -airborne * h * 0.035;

    // Squash on landing, stretch mid-air.
    final scaleY = 0.9 + 0.24 * airborne;
    final scaleX = 1.12 - 0.2 * airborne;

    // Shadow shrinks while airborne.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, groundY + 3),
        width: 34 * (1.1 - 0.45 * airborne),
        height: 7 * (1.1 - 0.45 * airborne),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.13),
    );

    canvas.save();
    canvas.translate(x, groundY + airY);
    canvas.rotate(math.sin(hopPhase * math.pi * 2) * 0.06);
    canvas.scale(scaleX, scaleY);
    canvas.translate(-23, -46); // rabbit box is 46x46, feet on origin
    RabbitPainter(
      bodyColor: Colors.white,
      outlineColor: const Color(0xFF5D4037),
    ).paint(canvas, const Size(46, 46));
    canvas.restore();
  }

  void _paintButterflies(Canvas canvas, double w, double h, double nearY) {
    for (int i = 0; i < 2; i++) {
      final baseX = ((t * (0.03 + i * 0.02) + i * 0.5) % 1.1) * w;
      final baseY = nearY - 24 - i * 18 + math.sin(t * 10 + i * 2) * 8;
      final flutter = (math.sin(t * 30 + i) * 0.5 + 0.5) * 0.8 + 0.2;
      final color = i == 0 ? const Color(0xFFFF8FB1) : const Color(0xFFFFD54F);
      final wing = Paint()..color = color.withValues(alpha: 0.9);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(baseX - 3 * flutter, baseY),
            width: 5 * flutter,
            height: 7),
        wing,
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(baseX + 3 * flutter, baseY),
            width: 5 * flutter,
            height: 7),
        wing,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MeadowPainter old) => old.t != t;
}

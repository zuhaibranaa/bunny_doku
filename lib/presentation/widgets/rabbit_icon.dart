import 'package:flutter/material.dart';

/// A cute rabbit icon — uses the bundled image when available,
/// otherwise falls back to the hand-drawn CustomPainter.
///
/// Used for placed rabbits on the grid, hearts, the region progress strip,
/// the splash screen and the map scene.
class RabbitIcon extends StatelessWidget {
  const RabbitIcon({
    super.key,
    this.size = 24,
    this.bodyColor = const Color(0xFF95918C),
    this.outlineColor = const Color(0xFF5C5B5A),
    this.innerEarColor = const Color(0xFFD9A8B0),
    this.eyeColor = const Color(0xFF3E2723),
    this.useImage = true,
  });

  final double size;
  final Color bodyColor;
  final Color outlineColor;
  final Color innerEarColor;
  final Color eyeColor;
  final bool useImage;

  @override
  Widget build(BuildContext context) {
    if (useImage) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          'assets/images/rabbit/rabbit.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => CustomPaint(
            size: Size.square(size),
            painter: RabbitPainter(
              bodyColor: bodyColor,
              outlineColor: outlineColor,
              innerEarColor: innerEarColor,
              eyeColor: eyeColor,
            ),
          ),
        ),
      );
    }

    return CustomPaint(
      size: Size.square(size),
      painter: RabbitPainter(
        bodyColor: bodyColor,
        outlineColor: outlineColor,
        innerEarColor: innerEarColor,
        eyeColor: eyeColor,
      ),
    );
  }
}

/// Paints the rabbit inside a 24x24 logical box (scaled to the given size).
///
/// Light/dark fur shades are derived from [bodyColor] so tinted variants
/// (gold hearts, greyed-out strip icons) keep the same layered look while
/// preserving their alpha.
class RabbitPainter extends CustomPainter {
  RabbitPainter({
    this.bodyColor = const Color(0xFF95918C),
    this.outlineColor = const Color(0xFF5C5B5A),
    this.innerEarColor = const Color(0xFFD9A8B0),
    this.eyeColor = const Color(0xFF3E2723),
    this.outlineWidth = 1.3,
  });

  final Color bodyColor;
  final Color outlineColor;
  final Color innerEarColor;
  final Color eyeColor;
  final double outlineWidth;

  static const _noseColor = Color(0xFFC8A5A0);
  static const _mouthColor = Color(0xFF5D5C5C);

  Color _lighten(Color c, double t) => c.withValues(
        red: c.r + (1 - c.r) * t,
        green: c.g + (1 - c.g) * t,
        blue: c.b + (1 - c.b) * t,
      );

  Color _darken(Color c, double t) => c.withValues(
        red: c.r * (1 - t),
        green: c.g * (1 - t),
        blue: c.b * (1 - t),
      );

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.save();
    canvas.scale(s, s);

    final fur = bodyColor;
    final furLight = _lighten(fur, 0.45);
    final furDark = _darken(fur, 0.3);

    final fill = Paint()..color = fur;
    final light = Paint()..color = furLight;
    final dark = Paint()..color = furDark;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlineWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = outlineColor;

    // ---- Ears (drawn first so the head covers their bases) --------------
    final leftEar = Path()
      ..moveTo(9.6, 11.6)
      ..quadraticBezierTo(7.6, 7.0, 8.6, 2.6)
      ..quadraticBezierTo(9.1, 1.0, 10.3, 2.0)
      ..quadraticBezierTo(11.6, 5.4, 12.2, 11.2)
      ..close();
    final rightEar = Path()
      ..moveTo(12.8, 11.2)
      ..quadraticBezierTo(13.4, 5.0, 14.8, 1.4)
      ..quadraticBezierTo(15.5, 0.2, 16.3, 1.5)
      ..quadraticBezierTo(17.4, 6.4, 16.0, 11.8)
      ..close();

    canvas.drawPath(leftEar, fill);
    canvas.drawPath(leftEar, outline);
    canvas.drawPath(rightEar, fill);
    canvas.drawPath(rightEar, outline);

    // Inner ear (dusty pink), inset inside each ear.
    final leftInner = Path()
      ..moveTo(10.4, 10.4)
      ..quadraticBezierTo(9.0, 6.8, 9.7, 3.4)
      ..quadraticBezierTo(10.0, 2.4, 10.6, 3.0)
      ..quadraticBezierTo(11.4, 5.8, 11.7, 10.2)
      ..close();
    final rightInner = Path()
      ..moveTo(13.6, 10.6)
      ..quadraticBezierTo(14.1, 5.4, 15.2, 2.6)
      ..quadraticBezierTo(15.6, 1.9, 16.0, 2.7)
      ..quadraticBezierTo(16.7, 6.6, 15.6, 10.8)
      ..close();
    canvas.drawPath(leftInner, Paint()..color = innerEarColor);
    canvas.drawPath(rightInner, Paint()..color = innerEarColor);

    // ---- Body (sitting, rounded) ----------------------------------------
    final body = Rect.fromCenter(
        center: const Offset(12, 19.7), width: 12.6, height: 8.6);
    canvas.drawOval(body, fill);
    // Subtle darker shading along the back (right side).
    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(14.6, 19.9), width: 6.4, height: 7.2),
      dark,
    );
    canvas.drawOval(body, outline);

    // Light chest patch.
    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(12, 20.1), width: 6.2, height: 6.6),
      light,
    );

    // Front paws.
    final pawL = Rect.fromCenter(
        center: const Offset(9.5, 23.0), width: 3.8, height: 2.0);
    final pawR = Rect.fromCenter(
        center: const Offset(14.5, 23.0), width: 3.8, height: 2.0);
    canvas.drawOval(pawL, light);
    canvas.drawOval(pawR, light);
    canvas.drawOval(pawL, outline);
    canvas.drawOval(pawR, outline);

    // ---- Head (covers ear bases and the top of the body) ----------------
    const headCenter = Offset(12, 13.4);
    const headR = 4.7;
    final headRect = Rect.fromCircle(center: headCenter, radius: headR);
    canvas.drawCircle(headCenter, headR, fill);
    // Darker cap on top of the head.
    canvas.drawArc(headRect, 3.14159, 3.14159, true, dark);
    // Light face / muzzle.
    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(12, 15.0), width: 6.6, height: 5.4),
      light,
    );
    canvas.drawCircle(headCenter, headR, outline);

    // ---- Face ------------------------------------------------------------
    // Eyes with catchlights.
    for (final ex in const [10.1, 13.9]) {
      canvas.drawCircle(Offset(ex, 13.6), 1.05, Paint()..color = eyeColor);
      canvas.drawCircle(
        Offset(ex - 0.3, 13.25),
        0.35,
        Paint()..color = Colors.white,
      );
    }

    // Nose (soft triangle).
    final nose = Path()
      ..moveTo(12, 15.6)
      ..lineTo(11.1, 14.9)
      ..lineTo(12.9, 14.9)
      ..close();
    canvas.drawPath(nose, Paint()..color = _noseColor);

    // Tiny w-shaped mouth.
    final mouth = Path()
      ..moveTo(11.1, 16.2)
      ..quadraticBezierTo(11.55, 16.75, 12.0, 16.25)
      ..quadraticBezierTo(12.45, 16.75, 12.9, 16.2);
    canvas.drawPath(
      mouth,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..strokeCap = StrokeCap.round
        ..color = _mouthColor,
    );

    // Faint whiskers.
    final whisker = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.35
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawLine(const Offset(10.6, 15.9), const Offset(7.3, 15.2), whisker);
    canvas.drawLine(const Offset(10.7, 16.4), const Offset(7.4, 16.7), whisker);
    canvas.drawLine(const Offset(13.4, 15.9), const Offset(16.7, 15.2), whisker);
    canvas.drawLine(const Offset(13.3, 16.4), const Offset(16.6, 16.7), whisker);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RabbitPainter old) =>
      old.bodyColor != bodyColor ||
      old.outlineColor != outlineColor ||
      old.innerEarColor != innerEarColor ||
      old.eyeColor != eyeColor ||
      old.outlineWidth != outlineWidth;
}

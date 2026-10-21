import 'package:flutter/material.dart';

/// Draws curved path lines between stage nodes on the map.
class MapPathPainter extends CustomPainter {
  final List<Offset> points;

  MapPathPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = Colors.purple.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final cp = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2 - 20);
      path.quadraticBezierTo(cp.dx, cp.dy, p1.dx, p1.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MapPathPainter old) =>
      old.points != points;
}

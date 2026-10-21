/// App-wide configuration constants.
import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = 'Bunny Doku';
  static const String packageName = 'com.rabitdoku.game';

  // Theme colors
  static const Color rabbitPurple = Color(0xFF8B5CF6);
  static const Color rabbitPink = Color(0xFFEC4899);
  static const Color rabbitBlue = Color(0xFF3B82F6);
  static const Color rabbitGreen = Color(0xFF10B981);
  static const Color rabbitYellow = Color(0xFFF59E0B);
  static const Color surfaceColor = Color(0xFFF8FAFC);
  static const Color cardColor = Color(0xFFFFFFFF);

  // Grid cell colors for regions.
  //
  // Regions must be easy to tell apart at a glance, so this palette is built
  // from widely spaced hues (roughly every 33-36 degrees) instead of a
  // rainbow of neighbouring tones. No two entries look alike, and the order
  // is deliberately shuffled so adjacent region ids never sit next to each
  // other on the colour wheel.
  static const List<Color> regionColors = [
    Color(0xFFE23A3A), // red
    Color(0xFF3B82F6), // blue
    Color(0xFFF2B705), // golden
    Color(0xFF8B5CF6), // violet
    Color(0xFF16A34A), // green
    Color(0xFFEC4899), // pink
    Color(0xFF22D3EE), // sky
    Color(0xFFA16207), // dark brown
    Color(0xFF14B8A6), // teal
    Color(0xFF5B3A29), // espresso
    Color(0xFF94A3B8), // slate
  ];
}

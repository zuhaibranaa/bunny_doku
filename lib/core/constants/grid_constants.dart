import 'package:flutter/material.dart';

/// Shared grid layout constants and palette helpers.
class GridConstants {
  static const double cellSpacing = 2.0;
  static const int maxGridSize = 10;

  // High-contrast region palette shared with `AppConfig.regionColors`.
  //
  // Kept in sync with AppConfig so no screen can accidentally render two
  // regions with near-identical colours. Each entry is a widely separated hue.
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

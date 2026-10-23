import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/rabbit_icon.dart';

/// Splash / loading screen with a bunny quote and a walking bunny that
/// traverses the progress bar (same style as the reference game).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const List<String> _quotes = [
    'Play for 30 minutes daily, you\'ll solve any puzzle with ease.',
    'A calm mind hops further than a fast one.',
    'Every bunny starts with a single hop.',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();

    Timer(const Duration(milliseconds: 2600), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/map');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2E1B),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Quote
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '"${_quotes[0]}"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),
            const Spacer(),
            // Logo
            const RabbitIcon(
              size: 152,
              bodyColor: Colors.white,
              outlineColor: Color(0xFF38A169),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bunnoku',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Bunny Sudoku Puzzle',
              style: TextStyle(color: Color(0xFF68D391), fontSize: 14),
            ),
            const Spacer(),
            // Progress bar with walking bunny
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = _controller.value;
                  return SizedBox(
                    height: 36,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Track
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        // Filled portion
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: t,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5A623),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        // Walking bunny (little hops)
                        Align(
                          alignment: Alignment(-1.0 + (t * 2.0), 0),
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              -3 * (0.5 - (0.5 - t % 0.25).abs() * 2).abs() * 2,
                            ),
                            child: const RabbitIcon(
                              size: 24,
                              bodyColor: Colors.white,
                              outlineColor: Color(0xFF8B6B6B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}

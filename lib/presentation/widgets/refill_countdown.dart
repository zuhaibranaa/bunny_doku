import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repositories/user_repository.dart';

/// Ticking countdown to the next extra-life refill (updates every second).
class RefillCountdown extends StatefulWidget {
  const RefillCountdown({super.key, required this.userRepo});

  final UserRepository userRepo;

  @override
  State<RefillCountdown> createState() => _RefillCountdownState();
}

class _RefillCountdownState extends State<RefillCountdown> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _format(int seconds) {
    if (seconds <= 0) return '00:00';
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final seconds = widget.userRepo.getSecondsUntilNextRefill();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer, size: 14, color: Colors.orange),
        const SizedBox(width: 3),
        Text(
          _format(seconds),
          style: const TextStyle(
            fontSize: 13,
            color: Colors.orange,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// The extra-lives pool (max 5, refill every 5 minutes) — shown on the map
/// only. Starting a stage consumes one.
class ExtraLivesPill extends StatefulWidget {
  const ExtraLivesPill({super.key, required this.userRepo});

  final UserRepository userRepo;

  @override
  State<ExtraLivesPill> createState() => _ExtraLivesPillState();
}

class _ExtraLivesPillState extends State<ExtraLivesPill> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Refresh when returning from a stage (pool consumed on entry).
    _ticker = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lives = widget.userRepo.getExtraLives();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.favorite, color: Colors.pink, size: 18),
        const SizedBox(width: 4),
        Text(
          '$lives/5',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
        ),
        if (lives < 5) ...[
          const SizedBox(width: 8),
          RefillCountdown(userRepo: widget.userRepo),
        ],
      ],
    );
  }
}

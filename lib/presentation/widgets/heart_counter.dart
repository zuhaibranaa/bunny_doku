import 'package:flutter/material.dart';

/// Heart counter widget showing remaining lives.
class HeartCounter extends StatelessWidget {
  final int hearts;
  final int maxHearts;

  const HeartCounter({
    super.key,
    required this.hearts,
    this.maxHearts = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxHearts, (index) {
        return Container(
          margin: const EdgeInsets.only(right: 6),
          child: Icon(
            index < hearts ? Icons.favorite : Icons.favorite_border,
            color: index < hearts ? Colors.red : Colors.grey.shade300,
            size: 20,
          ),
        );
      }),
    );
  }
}

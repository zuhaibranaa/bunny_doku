import 'package:flutter/material.dart';

/// Ad banner widget for the map screen.
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  @override
  Widget build(BuildContext context) {
    // Banner ad is loaded by AdProvider; this is a placeholder container
    // sized for a standard banner. AdProvider manages the actual ad.
    return SizedBox(
      height: 50,
      child: Center(
        child: Text(
          'Ad Banner',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        ),
      ),
    );
  }
}

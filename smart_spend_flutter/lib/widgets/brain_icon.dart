import 'package:flutter/material.dart';

/// Neural Circuit Brain AI icon matching user's custom asset
class BrainIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const BrainIcon({
    super.key,
    this.size = 20,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 3.0;
    final targetPixels = (size * pixelRatio).round().clamp(32, 256);

    return Image.asset(
      'assets/ai_brain.png',
      width: size,
      height: size,
      cacheWidth: targetPixels,
      cacheHeight: targetPixels,
      color: color,
      colorBlendMode: BlendMode.srcIn,
      fit: BoxFit.contain,
    );
  }
}

import 'package:flutter/material.dart';

/// Pixel-perfect Lucide 'Bot' icon matching the SmartSpend web application
class BotIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const BotIcon({
    super.key,
    this.size = 20,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BotPainter(
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _BotPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _BotPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 1. Antenna: M12 8V4H8
    final antennaPath = Path()
      ..moveTo(12, 8)
      ..lineTo(12, 4)
      ..lineTo(8, 4);
    canvas.drawPath(antennaPath, paint);

    // 2. Head: rect width="16" height="12" x="4" y="8" rx="2"
    final headRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(4, 8, 16, 12),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(headRRect, paint);

    // 3. Left Ear: M2 14h2
    canvas.drawLine(const Offset(2, 14), const Offset(4, 14), paint);

    // 4. Right Ear: M20 14h2
    canvas.drawLine(const Offset(20, 14), const Offset(22, 14), paint);

    // 5. Left Eye: M9 13v2
    canvas.drawLine(const Offset(9, 13), const Offset(9, 15), paint);

    // 6. Right Eye: M15 13v2
    canvas.drawLine(const Offset(15, 13), const Offset(15, 15), paint);
  }

  @override
  bool shouldRepaint(covariant _BotPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

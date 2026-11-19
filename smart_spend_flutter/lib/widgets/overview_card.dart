import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class OverviewCard extends StatelessWidget {
  final String title;
  final String amount;
  final String trend;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool positive;

  const OverviewCard({
    super.key,
    required this.title,
    required this.amount,
    required this.trend,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.positive = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: colors.borderSubtle == Colors.transparent
            ? null
            : Border.all(color: colors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top: Icon with dedicated breathing space
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),

          // Middle: Title & Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: colors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    color: colors.textMain,
                  ),
                ),
              ),
            ],
          ),

          // Bottom: Trend Label across full card width (never truncated)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: (positive ? colors.secondary : colors.danger)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  positive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 13,
                  color: positive ? colors.secondary : colors.danger,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    trend,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: positive ? colors.secondary : colors.danger,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

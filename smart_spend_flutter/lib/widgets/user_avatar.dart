import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  final double size;
  final double borderWidth;
  final Color? borderColor;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.initials,
    this.size = 36,
    this.borderWidth = 1.0,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>() ?? AppTheme.lightColors;
    final effectiveBorder = borderColor ?? colors.borderSubtle;
    final effectiveBg = backgroundColor ?? colors.surface2;

    final hasValidUrl = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effectiveBg,
        border: (borderWidth > 0 && effectiveBorder != Colors.transparent)
            ? Border.all(color: effectiveBorder, width: borderWidth)
            : null,
      ),
      child: ClipOval(
        child: hasValidUrl
            ? Image.network(
                avatarUrl!.trim(),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildInitials(colors),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildInitials(colors);
                },
              )
            : _buildInitials(colors),
      ),
    );
  }

  Widget _buildInitials(AppColors colors) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.bold,
          color: colors.primary,
        ),
      ),
    );
  }
}

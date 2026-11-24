import 'dart:io';
import 'package:flutter/material.dart';
import '../services/avatar_cache_service.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatefulWidget {
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
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  File? _cachedFile;

  @override
  void initState() {
    super.initState();
    _loadCachedAvatar();
  }

  @override
  void didUpdateWidget(covariant UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarUrl != widget.avatarUrl) {
      _loadCachedAvatar();
    }
  }

  void _loadCachedAvatar() {
    final url = widget.avatarUrl;
    if (url == null || url.trim().isEmpty) {
      if (_cachedFile != null) setState(() => _cachedFile = null);
      return;
    }

    // 1. Try immediate synchronous disk read (0ms latency, 100% offline)
    final syncFile = AvatarCacheService.instance.getCachedFileSync(url);
    if (syncFile != null && syncFile.existsSync()) {
      _cachedFile = syncFile;
      return;
    }

    // 2. Fetch/cache asynchronously
    AvatarCacheService.instance.getCachedFile(url).then((file) {
      if (mounted && file != null && file.existsSync()) {
        setState(() => _cachedFile = file);
      }
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>() ?? AppTheme.lightColors;
    final effectiveBorder = widget.borderColor ?? colors.borderSubtle;
    final effectiveBg = widget.backgroundColor ?? colors.surface2;

    Widget imageWidget;
    if (_cachedFile != null && _cachedFile!.existsSync()) {
      imageWidget = Image.file(
        _cachedFile!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildInitials(colors),
      );
    } else if (widget.avatarUrl != null && widget.avatarUrl!.trim().isNotEmpty) {
      imageWidget = Image.network(
        widget.avatarUrl!.trim(),
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildInitials(colors),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildInitials(colors);
        },
      );
    } else {
      imageWidget = _buildInitials(colors);
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effectiveBg,
        border: (widget.borderWidth > 0 && effectiveBorder != Colors.transparent)
            ? Border.all(color: effectiveBorder, width: widget.borderWidth)
            : null,
      ),
      child: ClipOval(child: imageWidget),
    );
  }

  Widget _buildInitials(AppColors colors) {
    return Center(
      child: Text(
        widget.initials,
        style: TextStyle(
          fontSize: widget.size * 0.38,
          fontWeight: FontWeight.bold,
          color: colors.primary,
        ),
      ),
    );
  }
}

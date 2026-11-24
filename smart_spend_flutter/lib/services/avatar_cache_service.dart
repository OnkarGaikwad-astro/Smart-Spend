import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Persistent local cache service for user profile pictures.
/// Ensures profile images display instantly even when the app is completely offline.
class AvatarCacheService {
  AvatarCacheService._();
  static final AvatarCacheService instance = AvatarCacheService._();

  Directory? _cacheDir;
  final Map<String, File> _memoryCache = {};

  Future<void> init() async {
    if (_cacheDir != null) return;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${docDir.path}/avatar_cache');
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
    } catch (e) {
      debugPrint('[AvatarCache] Init error: $e');
    }
  }

  String _generateFileName(String url) {
    final clean = url.trim();
    final safePrefix = clean
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final prefix = safePrefix.length > 24 ? safePrefix.substring(safePrefix.length - 24) : safePrefix;
    final hash = clean.hashCode.abs().toRadixString(16);
    return 'avatar_${prefix}_$hash.png';
  }

  /// Synchronous disk-check for 0ms offline display
  File? getCachedFileSync(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final clean = url.trim();

    if (clean.startsWith('file://')) {
      final file = File(clean.replaceFirst('file://', ''));
      if (file.existsSync()) return file;
    } else if (clean.startsWith('/') && File(clean).existsSync()) {
      return File(clean);
    }

    if (_memoryCache.containsKey(clean)) {
      final f = _memoryCache[clean]!;
      if (f.existsSync() && f.lengthSync() > 0) return f;
    }

    if (_cacheDir != null) {
      final filePath = '${_cacheDir!.path}/${_generateFileName(clean)}';
      final file = File(filePath);
      if (file.existsSync() && file.lengthSync() > 0) {
        _memoryCache[clean] = file;
        return file;
      }
    }
    return null;
  }

  /// Asynchronously retrieves cached file or downloads and stores locally
  Future<File?> getCachedFile(String? url) async {
    if (url == null || url.trim().isEmpty) return null;
    final clean = url.trim();

    if (clean.startsWith('file://')) {
      final f = File(clean.replaceFirst('file://', ''));
      if (await f.exists()) return f;
    }
    if (clean.startsWith('/') && await File(clean).exists()) {
      return File(clean);
    }

    await init();
    if (_cacheDir == null) return null;

    final fileName = _generateFileName(clean);
    final file = File('${_cacheDir!.path}/$fileName');

    if (await file.exists() && await file.length() > 0) {
      _memoryCache[clean] = file;
      return file;
    }

    // Download from network and cache
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      try {
        final response = await http
            .get(Uri.parse(clean))
            .timeout(const Duration(seconds: 12));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          await file.writeAsBytes(response.bodyBytes);
          _memoryCache[clean] = file;
          return file;
        }
      } catch (e) {
        debugPrint('[AvatarCache] Download failed for $clean: $e');
      }
    }

    return null;
  }

  /// Pre-cache avatar in the background on login or profile sync
  Future<void> preCacheAvatar(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    try {
      await getCachedFile(url);
    } catch (_) {}
  }

  /// Clear cached avatar files
  Future<void> clearCache() async {
    try {
      _memoryCache.clear();
      if (_cacheDir != null && await _cacheDir!.exists()) {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create(recursive: true);
      }
    } catch (e) {
      debugPrint('[AvatarCache] Clear cache error: $e');
    }
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../theme/app_theme.dart';

/// Data class holding GitHub release information
class AppUpdateInfo {
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;
  final String releasePageUrl;
  final DateTime? publishedAt;
  final bool isPrerelease;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.releasePageUrl,
    this.publishedAt,
    this.isPrerelease = false,
  });
}

/// Service to check for new app versions on GitHub Releases and notify users.
class UpdateCheckerService {
  UpdateCheckerService._();
  static final UpdateCheckerService instance = UpdateCheckerService._();

  bool _isChecking = false;
  DateTime? _lastCheckedTime;
  AppUpdateInfo? _cachedUpdateInfo;

  /// Compare two semantic version strings (e.g. '1.0.1' > '1.0.0')
  static bool isNewerVersion(String latestStr, String currentStr) {
    try {
      final cleanLatest = latestStr.toLowerCase().replaceAll(RegExp(r'[^0-9.]'), '');
      final cleanCurrent = currentStr.toLowerCase().replaceAll(RegExp(r'[^0-9.]'), '');

      final latestParts = cleanLatest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      while (latestParts.length < 3) {
        latestParts.add(0);
      }
      while (currentParts.length < 3) {
        currentParts.add(0);
      }

      for (var i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Check GitHub Releases for newer version
  Future<AppUpdateInfo?> checkForUpdate({bool silent = true}) async {
    if (_isChecking) return _cachedUpdateInfo;
    _isChecking = true;

    try {
      final uri = Uri.parse(AppConstants.githubReleasesApiUrl);
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'SmartSpend-App/${AppConstants.appVersion}',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tagName = data['tag_name']?.toString() ?? '';
        final body = data['body']?.toString() ?? 'Bug fixes and performance improvements.';
        final htmlUrl = data['html_url']?.toString() ?? AppConstants.githubReleasesUrl;
        final isPrerelease = data['prerelease'] == true;
        final publishedAtStr = data['published_at']?.toString();
        final publishedAt = publishedAtStr != null ? DateTime.tryParse(publishedAtStr) : null;

        // Find direct .apk asset if uploaded
        String downloadUrl = htmlUrl;
        if (data['assets'] is List) {
          final assets = data['assets'] as List;
          for (final asset in assets) {
            final name = asset['name']?.toString().toLowerCase() ?? '';
            if (name.endsWith('.apk')) {
              downloadUrl = asset['browser_download_url']?.toString() ?? downloadUrl;
              break;
            }
          }
        }

        if (isNewerVersion(tagName, AppConstants.appVersion)) {
          final info = AppUpdateInfo(
            latestVersion: tagName.startsWith('v') ? tagName : 'v$tagName',
            releaseNotes: body,
            downloadUrl: downloadUrl,
            releasePageUrl: htmlUrl,
            publishedAt: publishedAt,
            isPrerelease: isPrerelease,
          );
          _cachedUpdateInfo = info;
          _lastCheckedTime = DateTime.now();
          return info;
        }
      }
    } catch (e) {
      if (!silent) {
        debugPrint('[UpdateChecker] Error checking GitHub releases: $e');
      }
    } finally {
      _isChecking = false;
    }

    return null;
  }

  /// Run check after app cold start without blocking UI
  Future<void> checkOnStartup(BuildContext context) async {
    // Wait for the dashboard to finish rendering
    await Future.delayed(const Duration(seconds: 4));
    if (!context.mounted) return;

    // Check once per session
    if (_lastCheckedTime != null &&
        DateTime.now().difference(_lastCheckedTime!).inHours < 6) {
      return;
    }

    final update = await checkForUpdate(silent: true);
    if (update != null && context.mounted) {
      showUpdateDialog(context, update);
    }
  }

  /// Show professional update dialog
  static void showUpdateDialog(BuildContext context, AppUpdateInfo info) {
    HapticFeedback.mediumImpact();
    final colors = Theme.of(context).extension<AppColors>() ?? AppTheme.lightColors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: colors.borderSubtle == Colors.transparent
                  ? Colors.white10
                  : colors.borderSubtle,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header: Icon + Version Tag
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.primary, colors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Update Available',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.textMain,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colors.primary.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                info.latestVersion,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Installed: v${AppConstants.appVersion}',
                          style: TextStyle(fontSize: 12, color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Release notes box
              Text(
                "What's New in ${info.latestVersion}",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colors.borderSubtle == Colors.transparent
                        ? Colors.white10
                        : colors.borderSubtle,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    info.releaseNotes.trim().isNotEmpty
                        ? info.releaseNotes.trim()
                        : '• New features and performance improvements\n• Bug fixes and UI enhancements',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: colors.textMain.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(
                          color: colors.borderSubtle == Colors.transparent
                              ? Colors.white24
                              : colors.borderSubtle,
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Later',
                        style: TextStyle(color: colors.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final uri = Uri.parse(info.downloadUrl);
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          debugPrint('[UpdateChecker] Launch error: $e');
                        }
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download_rounded, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Download Update',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

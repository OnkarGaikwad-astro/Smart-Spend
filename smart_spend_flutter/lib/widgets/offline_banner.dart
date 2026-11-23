import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final colors = AppTheme.of(context);

    if (provider.isOnline && provider.pendingSyncCount == 0 && !provider.isSyncing) {
      return const SizedBox.shrink();
    }

    final isOffline = !provider.isOnline;
    final isSyncing = provider.isSyncing;
    final pending = provider.pendingSyncCount;

    Color bgColor = colors.surface2;
    Color textColor = colors.textMain;
    IconData icon = Icons.cloud_done_rounded;
    String text = 'All changes synced';

    if (isOffline) {
      bgColor = colors.dangerSoft;
      textColor = colors.danger;
      icon = Icons.cloud_off_rounded;
      text = 'Offline Mode • $pending changes queued locally';
    } else if (isSyncing) {
      bgColor = colors.primarySoft;
      textColor = colors.primary;
      icon = Icons.sync_rounded;
      text = 'Syncing $pending changes with database...';
    } else if (pending > 0) {
      bgColor = colors.secondarySoft;
      textColor = colors.primary;
      icon = Icons.cloud_upload_outlined;
      text = '$pending changes ready to sync';
    }

    return InkWell(
      onTap: isSyncing
          ? null
          : () async {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isOffline
                        ? 'You are currently offline. Changes will sync once reconnected.'
                        : 'Syncing $pending changes with Supabase...',
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              if (!isOffline) {
                await provider.syncNow();
              }
            },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            bottom: BorderSide(color: colors.borderSubtle, width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isSyncing
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                : Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

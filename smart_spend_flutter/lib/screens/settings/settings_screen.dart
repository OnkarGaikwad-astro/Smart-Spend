import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../services/pdf_export_service.dart';
import '../../services/tts_service.dart';
import '../../services/update_checker_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import 'about_developer_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final appProvider = context.watch<AppProvider>();
    final authProvider = context.watch<AuthProvider>();
    final profile = appProvider.userProfile ?? authProvider.userProfile;
    final email = profile?.email ?? authProvider.currentUser?.email ?? 'user@smartspend.app';
    final fullName = profile?.fullName ?? 'SmartSpend User';
    final initials = profile?.initials ?? 'U';
    final avatarUrl = profile?.avatarUrl ??
        authProvider.currentUser?.userMetadata?['avatar_url']?.toString() ??
        authProvider.currentUser?.userMetadata?['picture']?.toString();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textMain, size: 20),
          onPressed: () {
            if (appProvider.hapticsEnabled) HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Settings & Preferences',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.textMain,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // 1. Profile Header Card
          _buildProfileCard(context, colors, appProvider, authProvider, fullName, email, initials, avatarUrl),
          const SizedBox(height: 24),

          // 2. Appearance & Theme Mode
          _buildSectionHeader('APPEARANCE & THEME', colors),
          const SizedBox(height: 8),
          _buildThemeSelector(context, colors, appProvider),
          const SizedBox(height: 24),

          // 3. General & Display Preferences (Privacy mode removed per user request)
          _buildSectionHeader('PREFERENCES & DISPLAY', colors),
          const SizedBox(height: 8),
          _buildSettingsCard(
            colors: colors,
            children: [
              _buildCurrencyTile(context, colors, appProvider),
              _buildDivider(colors),
              _buildDefaultPaymentModeTile(context, colors, appProvider),
              _buildDivider(colors),
              _buildDefaultCategoryTile(context, colors, appProvider),
              _buildDivider(colors),
              _buildSwitchTile(
                icon: Icons.auto_awesome_rounded,
                iconColor: colors.primary,
                title: 'Smart Auto-Categorize',
                subtitle: 'Suggest categories based on merchant name and transaction notes',
                value: appProvider.smartAutoCategorize,
                onChanged: (val) {
                  if (appProvider.hapticsEnabled) HapticFeedback.selectionClick();
                  appProvider.setSmartAutoCategorize(val);
                },
                colors: colors,
              ),
              _buildDivider(colors),
              _buildSwitchTile(
                icon: Icons.numbers_rounded,
                iconColor: colors.secondary,
                title: 'Show Decimal Amounts',
                subtitle: 'Display exact paise/cents (₹0.00) across transactions and cards',
                value: appProvider.showDecimals,
                onChanged: (val) {
                  if (appProvider.hapticsEnabled) HapticFeedback.selectionClick();
                  appProvider.setShowDecimals(val);
                },
                colors: colors,
              ),
              _buildDivider(colors),
              _buildSwitchTile(
                icon: Icons.calendar_view_week_rounded,
                iconColor: colors.purple,
                title: 'Start Week on Monday',
                subtitle: 'Weekly budgets, charts, and summaries begin on Monday',
                value: appProvider.weekStartMonday,
                onChanged: (val) {
                  if (appProvider.hapticsEnabled) HapticFeedback.selectionClick();
                  appProvider.setWeekStartMonday(val);
                },
                colors: colors,
              ),
              _buildDivider(colors),
              _buildSwitchTile(
                icon: Icons.volume_up_rounded,
                iconColor: colors.primary,
                title: 'Auto-Speak AI Replies',
                subtitle: 'Speak Aurex AI assistant replies aloud automatically',
                value: appProvider.autoSpeakAiReplies,
                onChanged: (val) {
                  if (appProvider.hapticsEnabled) HapticFeedback.selectionClick();
                  appProvider.setAutoSpeakAiReplies(val);
                },
                colors: colors,
              ),
              _buildDivider(colors),
              _buildSwitchTile(
                icon: Icons.graphic_eq_rounded,
                iconColor: colors.secondary,
                title: 'In-App Sound Effects',
                subtitle: 'Audio chimes on successful transactions and actions',
                value: appProvider.soundEffectsEnabled,
                onChanged: (val) {
                  if (appProvider.hapticsEnabled) HapticFeedback.selectionClick();
                  appProvider.setSoundEffectsEnabled(val);
                },
                colors: colors,
              ),
              _buildDivider(colors),
              _buildSwitchTile(
                icon: Icons.vibration_rounded,
                iconColor: colors.purple,
                title: 'Haptic Feedback',
                subtitle: 'Tactile vibration response on actions and gestures',
                value: appProvider.hapticsEnabled,
                onChanged: (val) {
                  appProvider.setHapticsEnabled(val);
                  if (val) HapticFeedback.mediumImpact();
                },
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 4. Notifications & Reminders
          _buildSectionHeader('NOTIFICATIONS & HABITS', colors),
          const SizedBox(height: 8),
          _buildSettingsCard(
            colors: colors,
            children: [
              _buildSwitchTile(
                icon: Icons.alarm_rounded,
                iconColor: colors.primary,
                title: 'Daily Expense Logging (9 PM)',
                subtitle: 'Gentle reminder each evening to log today\'s spending',
                value: appProvider.dailyReminderEnabled,
                onChanged: (val) {
                  if (appProvider.hapticsEnabled) HapticFeedback.selectionClick();
                  appProvider.setDailyReminderEnabled(val);
                },
                colors: colors,
              ),
              _buildDivider(colors),
              _buildSwitchTile(
                icon: Icons.warning_amber_rounded,
                iconColor: colors.danger,
                title: 'Budget Limit Alerts',
                subtitle: 'Warn when spending exceeds 80% or 100% of category',
                value: appProvider.budgetAlertsEnabled,
                onChanged: (val) {
                  if (appProvider.hapticsEnabled) HapticFeedback.selectionClick();
                  appProvider.setBudgetAlertsEnabled(val);
                },
                colors: colors,
              ),
              _buildDivider(colors),
              _buildSwitchTile(
                icon: Icons.handshake_outlined,
                iconColor: colors.secondary,
                title: 'Khata & Debt Due Reminders',
                subtitle: 'Notify before borrower repayments or settled dates',
                value: appProvider.debtRemindersEnabled,
                onChanged: (val) {
                  if (appProvider.hapticsEnabled) HapticFeedback.selectionClick();
                  appProvider.setDebtRemindersEnabled(val);
                },
                colors: colors,
              ),
              _buildDivider(colors),
              _buildActionTile(
                icon: Icons.notifications_active_outlined,
                iconColor: colors.primary,
                title: 'Send Test Notification',
                subtitle: 'Verify sound, vibration, and push notification delivery',
                onTap: () async {
                  if (appProvider.hapticsEnabled) HapticFeedback.mediumImpact();
                  final granted = await NotificationService().requestPermission();
                  if (granted) {
                    await NotificationService().sendTestNotification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text('Notification sent! Check your status bar.'),
                            ],
                          ),
                          backgroundColor: colors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please allow notification permissions in Android settings.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 5. Aurex AI & Voice Assistant
          _buildSectionHeader('AUREX AI & VOICE ASSISTANT', colors),
          const SizedBox(height: 8),
          _VoiceAssistantSettingsCard(colors: colors),
          const SizedBox(height: 24),

          // 6. Cloud Sync & Data Management
          _buildSectionHeader('DATA, BACKUP & CLOUD', colors),
          const SizedBox(height: 8),
          _buildSettingsCard(
            colors: colors,
            children: [
              _buildSyncTile(context, colors, appProvider),
              _buildDivider(colors),
              _buildActionTile(
                icon: Icons.file_download_outlined,
                iconColor: colors.primary,
                title: 'Export All Data to CSV',
                subtitle: 'Export transactions, debts, and budgets into portable CSV format',
                onTap: () => _exportCsv(context, appProvider),
                colors: colors,
              ),
              _buildDivider(colors),
              _buildActionTile(
                icon: Icons.picture_as_pdf_rounded,
                iconColor: colors.danger,
                title: 'Export Transactions to PDF',
                subtitle: 'Generate a clean, professional financial statement with summary and history',
                onTap: () => _exportPdf(context, appProvider, authProvider),
                colors: colors,
              ),
              _buildDivider(colors),
              _buildActionTile(
                icon: Icons.delete_sweep_outlined,
                iconColor: colors.danger,
                title: 'Clear Local Storage Cache',
                subtitle: 'Delete locally stored offline cache without deleting cloud records',
                onTap: () => _confirmClearCache(context, colors, appProvider),
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 6. Creator & Developer Profile
          _buildSectionHeader('CREATOR & DEVELOPER', colors),
          const SizedBox(height: 8),
          _buildCreatorCard(context, colors),
          const SizedBox(height: 24),

          // 7. About, Legal & Licenses
          _buildSectionHeader('ABOUT SMARTSPEND', colors),
          const SizedBox(height: 8),
          _buildSettingsCard(
            colors: colors,
            children: [
              _buildInfoTile(
                icon: Icons.info_outline_rounded,
                iconColor: colors.primary,
                title: 'Version',
                trailingText: 'v${AppConstants.appVersion} (Build ${AppConstants.appBuildNumber})',
                colors: colors,
              ),
              _buildDivider(colors),
              _buildActionTile(
                icon: Icons.system_update_rounded,
                iconColor: colors.secondary,
                title: 'Check for Updates',
                subtitle: 'Check GitHub Releases for latest updates',
                onTap: () => _manualCheckUpdate(context, colors),
                colors: colors,
              ),
              _buildDivider(colors),
              _buildActionTile(
                icon: Icons.policy_outlined,
                iconColor: colors.textMuted,
                title: 'Privacy Policy & Terms',
                subtitle: 'Read how your financial data is protected and encrypted',
                onTap: () => _showPrivacyPolicy(context, colors),
                colors: colors,
              ),
              _buildDivider(colors),
              _buildActionTile(
                icon: Icons.code_rounded,
                iconColor: colors.textMuted,
                title: 'Open Source Licenses',
                subtitle: 'View software licenses powering SmartSpend',
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'SmartSpend AI',
                    applicationVersion: '1.0.0',
                    applicationIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset('assets/icon.png', width: 64, height: 64),
                    ),
                  );
                },
                colors: colors,
              ),
              _buildDivider(colors),
              _buildActionTile(
                icon: Icons.share_rounded,
                iconColor: colors.secondary,
                title: 'Share SmartSpend App',
                subtitle: 'Recommend SmartSpend to friends, family, and colleagues',
                onTap: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text: 'Track your personal expenses, budgets, and khata debts effortlessly with SmartSpend AI: https://smartspend.astronkar.in',
                    ),
                  );
                },
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // 7. Sign Out Button
          Container(
            decoration: BoxDecoration(
              color: colors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.danger.withValues(alpha: 0.25)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Icon(Icons.logout_rounded, color: colors.danger),
              title: Text(
                'Sign Out',
                style: TextStyle(
                  color: colors.danger,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                'Signed in as $email',
                style: TextStyle(
                  color: colors.danger.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
              onTap: () => _confirmSignOut(context, colors, authProvider, appProvider),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // --- Profile Summary Header Card ---
  Widget _buildProfileCard(
    BuildContext context,
    AppColors colors,
    AppProvider appProvider,
    AuthProvider authProvider,
    String fullName,
    String email,
    String initials,
    String? avatarUrl,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: colors.borderSubtle == Colors.transparent
            ? null
            : Border.all(color: colors.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          UserAvatar(
            avatarUrl: avatarUrl,
            initials: initials,
            size: 56,
            borderWidth: 2,
            borderColor: colors.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        fullName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.textMain,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _showEditNameDialog(context, colors, appProvider, fullName),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.edit_outlined, size: 16, color: colors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primarySoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user_rounded, size: 12, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Cloud Sync Active • Pro Member',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Visual Theme & Accent Palette Selector ---
  Widget _buildThemeSelector(BuildContext context, AppColors colors, AppProvider appProvider) {
    final currentMode = appProvider.themeModeString;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: colors.borderSubtle == Colors.transparent
            ? null
            : Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme Mode',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textMain,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.surface2,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildThemeOption(
                  context: context,
                  title: 'System',
                  icon: Icons.brightness_auto_rounded,
                  isSelected: currentMode == 'system',
                  onTap: () {
                    if (appProvider.hapticsEnabled) HapticFeedback.selectionClick();
                    appProvider.setThemeMode(ThemeMode.system);
                  },
                  colors: colors,
                ),
                const SizedBox(width: 6),
                _buildThemeOption(
                  context: context,
                  title: 'Light',
                  icon: Icons.light_mode_rounded,
                  isSelected: currentMode == 'light',
                  onTap: () {
                    if (appProvider.hapticsEnabled) HapticFeedback.selectionClick();
                    appProvider.setThemeMode(ThemeMode.light);
                  },
                  colors: colors,
                ),
                const SizedBox(width: 6),
                _buildThemeOption(
                  context: context,
                  title: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  isSelected: currentMode == 'dark',
                  onTap: () {
                    if (appProvider.hapticsEnabled) HapticFeedback.selectionClick();
                    appProvider.setThemeMode(ThemeMode.dark);
                  },
                  colors: colors,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Divider(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Accent Color Theme',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textMain,
                ),
              ),
              Text(
                AppTheme.availablePalettes
                    .firstWhere((p) => p.key == appProvider.colorPalette,
                        orElse: () => AppTheme.availablePalettes.first)
                    .name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Horizontal Swatches of all 6 themes
          SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppTheme.availablePalettes.length,
              separatorBuilder: (_, index) => const SizedBox(width: 10),
              itemBuilder: (ctx, index) {
                final palette = AppTheme.availablePalettes[index];
                final isSelected = appProvider.colorPalette == palette.key;
                return InkWell(
                  onTap: () {
                    if (appProvider.hapticsEnabled) HapticFeedback.mediumImpact();
                    appProvider.setColorPalette(palette.key);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? palette.primaryColor.withValues(alpha: 0.15)
                          : colors.surface2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? palette.primaryColor : colors.borderSubtle,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: palette.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: palette.primaryColor.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                              : null,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          palette.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? palette.primaryColor : colors.textMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required AppColors colors,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : colors.textMuted,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Currency Picker Tile ---
  Widget _buildCurrencyTile(BuildContext context, AppColors colors, AppProvider appProvider) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.primarySoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            appProvider.currencySymbol,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
        ),
      ),
      title: Text(
        'Currency Symbol',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textMain),
      ),
      subtitle: Text(
        'Select preferred currency for accounts and formatting',
        style: TextStyle(fontSize: 12, color: colors.textMuted),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colors.surface2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              appProvider.currencySymbol,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.primary,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 16, color: colors.textMuted),
          ],
        ),
      ),
      onTap: () => _showCurrencyPicker(context, colors, appProvider),
    );
  }

  // --- Default Payment Mode Tile ---
  Widget _buildDefaultPaymentModeTile(
      BuildContext context, AppColors colors, AppProvider appProvider) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.primarySoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.account_balance_wallet_rounded, color: colors.primary, size: 20),
      ),
      title: Text(
        'Default Payment Method',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textMain),
      ),
      subtitle: Text(
        'Auto-selected when logging new expenses',
        style: TextStyle(fontSize: 12, color: colors.textMuted),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colors.surface2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              appProvider.defaultPaymentMode,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.primary,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 16, color: colors.textMuted),
          ],
        ),
      ),
      onTap: () => _showPaymentModePicker(context, colors, appProvider),
    );
  }

  void _showPaymentModePicker(
      BuildContext context, AppColors colors, AppProvider appProvider) {
    if (appProvider.hapticsEnabled) HapticFeedback.lightImpact();
    final modes = [
      {'title': 'UPI', 'subtitle': 'Google Pay, PhonePe, Paytm', 'icon': Icons.qr_code_2_rounded},
      {'title': 'Cash', 'subtitle': 'Physical cash & wallet', 'icon': Icons.payments_rounded},
      {'title': 'Bank Transfer', 'subtitle': 'IMPS, NEFT, Net Banking', 'icon': Icons.account_balance_rounded},
      {'title': 'Credit Card', 'subtitle': 'Credit card spends', 'icon': Icons.credit_card_rounded},
      {'title': 'Debit Card', 'subtitle': 'Bank debit card', 'icon': Icons.credit_card_outlined},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Default Payment Method',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.textMain,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: colors.textMuted, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ...modes.map((m) {
                  final title = m['title'] as String;
                  final subtitle = m['subtitle'] as String;
                  final icon = m['icon'] as IconData;
                  final isSelected = appProvider.defaultPaymentMode == title;

                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? colors.primarySoft : colors.surface2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: isSelected ? colors.primary : colors.textMuted, size: 20),
                    ),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? colors.primary : colors.textMain,
                      ),
                    ),
                    subtitle: Text(subtitle, style: TextStyle(color: colors.textMuted, fontSize: 11)),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded, color: colors.primary, size: 20)
                        : null,
                    onTap: () {
                      if (appProvider.hapticsEnabled) HapticFeedback.selectionClick();
                      appProvider.setDefaultPaymentMode(title);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Default Category Tile ---
  Widget _buildDefaultCategoryTile(
      BuildContext context, AppColors colors, AppProvider appProvider) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.secondary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.category_rounded, color: colors.secondary, size: 20),
      ),
      title: Text(
        'Default Category',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textMain),
      ),
      subtitle: Text(
        'Initial category when opening expense form',
        style: TextStyle(fontSize: 12, color: colors.textMuted),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colors.surface2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              appProvider.defaultCategory,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.secondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 16, color: colors.textMuted),
          ],
        ),
      ),
      onTap: () => _showCategoryPicker(context, colors, appProvider),
    );
  }

  void _showCategoryPicker(
      BuildContext context, AppColors colors, AppProvider appProvider) {
    if (appProvider.hapticsEnabled) HapticFeedback.lightImpact();
    final categories = [
      {'name': 'Food & Dining', 'icon': Icons.restaurant_rounded},
      {'name': 'Shopping', 'icon': Icons.shopping_bag_rounded},
      {'name': 'Transport', 'icon': Icons.directions_bus_rounded},
      {'name': 'Bills & Utilities', 'icon': Icons.receipt_long_rounded},
      {'name': 'Subscriptions', 'icon': Icons.subscriptions_rounded},
      {'name': 'Entertainment', 'icon': Icons.movie_rounded},
      {'name': 'Savings & Investments', 'icon': Icons.savings_rounded},
      {'name': 'General / Other', 'icon': Icons.more_horiz_rounded},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.6,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Default Expense Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.textMain,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: colors.textMuted, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: categories.map((c) {
                      final name = c['name'] as String;
                      final icon = c['icon'] as IconData;
                      final isSelected = appProvider.defaultCategory == name;

                      return ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected ? colors.primarySoft : colors.surface2,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: isSelected ? colors.primary : colors.textMuted, size: 20),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? colors.primary : colors.textMain,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: colors.primary, size: 20)
                            : null,
                        onTap: () {
                          if (appProvider.hapticsEnabled) HapticFeedback.selectionClick();
                          appProvider.setDefaultCategory(name);
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Cloud Sync Tile ---
  Widget _buildSyncTile(BuildContext context, AppColors colors, AppProvider appProvider) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (appProvider.isOnline ? colors.success : colors.danger).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          appProvider.isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
          color: appProvider.isOnline ? colors.success : colors.danger,
          size: 20,
        ),
      ),
      title: Text(
        appProvider.isOnline ? 'Cloud Sync Online' : 'Offline Mode',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textMain),
      ),
      subtitle: Text(
        appProvider.pendingSyncCount > 0
            ? '${appProvider.pendingSyncCount} changes waiting to upload'
            : 'All transactions & debts synced to Supabase',
        style: TextStyle(fontSize: 12, color: colors.textMuted),
      ),
      trailing: ElevatedButton.icon(
        icon: appProvider.isSyncing
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              )
            : const Icon(Icons.sync_rounded, size: 16),
        label: Text(appProvider.isSyncing ? 'Syncing...' : 'Sync Now'),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primarySoft,
          foregroundColor: colors.primary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: appProvider.isSyncing ? null : () => appProvider.fetchData(),
      ),
    );
  }

  // --- CSV Export Action ---
  Future<void> _exportCsv(BuildContext context, AppProvider appProvider) async {
    if (appProvider.hapticsEnabled) HapticFeedback.mediumImpact();
    final csvData = AppUtils.generateCsvExport(
      transactions: appProvider.transactions,
      debts: appProvider.debts,
    );

    await SharePlus.instance.share(
      ShareParams(
        text: csvData,
        subject: 'SmartSpend_Export_${DateTime.now().toIso8601String().split('T')[0]}.csv',
      ),
    );
  }

  // --- PDF Transactions Export Action ---
  Future<void> _exportPdf(BuildContext context, AppProvider appProvider, AuthProvider authProvider) async {
    if (appProvider.hapticsEnabled) HapticFeedback.mediumImpact();
    if (appProvider.transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions available to export.')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating PDF statement...'),
          duration: Duration(seconds: 1),
        ),
      );

      await PdfExportService.exportTransactionsPdf(
        transactions: appProvider.transactions,
        totalIncome: appProvider.totalIncome,
        totalExpense: appProvider.totalExpense,
        netBalance: appProvider.totalBalance,
        userProfile: authProvider.userProfile ?? appProvider.userProfile,
      );
    } catch (e) {
      debugPrint('[Settings] PDF export error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    }
  }

  // --- Currency Picker Bottom Sheet ---
  void _showCurrencyPicker(BuildContext context, AppColors colors, AppProvider appProvider) {
    if (appProvider.hapticsEnabled) HapticFeedback.lightImpact();

    final currencies = [
      {'symbol': '₹', 'code': 'INR', 'name': 'Indian Rupee'},
      {'symbol': '\$', 'code': 'USD', 'name': 'United States Dollar'},
      {'symbol': '€', 'code': 'EUR', 'name': 'Euro'},
      {'symbol': '£', 'code': 'GBP', 'name': 'British Pound'},
      {'symbol': '¥', 'code': 'JPY', 'name': 'Japanese Yen'},
      {'symbol': 'د.إ', 'code': 'AED', 'name': 'UAE Dirham'},
      {'symbol': 'C\$', 'code': 'CAD', 'name': 'Canadian Dollar'},
      {'symbol': 'A\$', 'code': 'AUD', 'name': 'Australian Dollar'},
      {'symbol': 'S\$', 'code': 'SGD', 'name': 'Singapore Dollar'},
      {'symbol': 'RM', 'code': 'MYR', 'name': 'Malaysian Ringgit'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderSubtle == Colors.transparent
                      ? Colors.grey.withValues(alpha: 0.3)
                      : colors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Choose Currency',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textMain,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: currencies.length,
                  separatorBuilder: (_, index) => Divider(height: 1, color: colors.borderSubtle),
                  itemBuilder: (c, idx) {
                    final curr = currencies[idx];
                    final isSelected = appProvider.currencySymbol == curr['symbol'];
                    return ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected ? colors.primary : colors.surface2,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            curr['symbol']!,
                            style: TextStyle(
                              color: isSelected ? Colors.white : colors.textMain,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        curr['name']!,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: colors.textMain,
                        ),
                      ),
                      subtitle: Text(curr['code']!, style: TextStyle(color: colors.textMuted)),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: colors.primary)
                          : null,
                      onTap: () {
                        if (appProvider.hapticsEnabled) HapticFeedback.selectionClick();
                        appProvider.setCurrencySymbol(curr['symbol']!);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Edit Name Dialog ---
  void _showEditNameDialog(
    BuildContext context,
    AppColors colors,
    AppProvider appProvider,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Name',
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.textMain),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: colors.textMain),
          decoration: InputDecoration(
            labelText: 'Full Name',
            labelStyle: TextStyle(color: colors.textMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save'),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await appProvider.updateProfile(fullName: newName);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  // --- Clear Cache Confirmation ---
  void _confirmClearCache(BuildContext context, AppColors colors, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear Local Cache?',
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.textMain),
        ),
        content: Text(
          'This will clear your local temporary storage. Cloud records stored in Supabase will NOT be deleted.',
          style: TextStyle(color: colors.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Clear Cache'),
            onPressed: () async {
              await appProvider.clearAllData();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Local cache cleared successfully!')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // --- Sign Out Confirmation ---
  void _confirmSignOut(
    BuildContext context,
    AppColors colors,
    AuthProvider authProvider,
    AppProvider appProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out of SmartSpend?',
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.textMain),
        ),
        content: Text(
          'You will be returned to the login screen. Your local data remains securely synced to your cloud account.',
          style: TextStyle(color: colors.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out'),
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context); // Close Settings screen
              await authProvider.signOut();
            },
          ),
        ],
      ),
    );
  }

  // --- Check for App Updates ---
  Future<void> _manualCheckUpdate(BuildContext context, AppColors colors) async {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking GitHub Releases for updates...'),
        duration: Duration(seconds: 1),
      ),
    );

    final updateInfo = await UpdateCheckerService.instance.checkForUpdate(silent: false);
    if (!context.mounted) return;

    if (updateInfo != null) {
      UpdateCheckerService.showUpdateDialog(context, updateInfo);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You're using the latest version of SmartSpend (v${AppConstants.appVersion}) 🎉",
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // --- Privacy Policy Dialog ---
  void _showPrivacyPolicy(BuildContext context, AppColors colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Privacy & Security Guarantee',
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.textMain),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Local-First Architecture',
                style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'SmartSpend stores your transactions, debts, and budgets locally on your device in encrypted storage for instant offline access.',
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Text(
                '2. Bank-Grade Cloud Encryption',
                style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Cloud sync is backed by Supabase with Row Level Security (RLS). Only your authenticated account can read or modify your financial data.',
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Text(
                '3. AI Privacy',
                style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Aurex AI requests are transmitted securely to Gemini API and are never used to train global public models.',
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Got It'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildSectionHeader(String title, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: colors.textMuted,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children, required AppColors colors}) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: colors.borderSubtle == Colors.transparent
            ? null
            : Border.all(color: colors.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required AppColors colors,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textMain),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: colors.textMuted),
      ),
      activeTrackColor: colors.primary,
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required AppColors colors,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textMain),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: colors.textMuted),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: colors.textMuted, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String trailingText,
    required AppColors colors,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textMain),
      ),
      trailing: Text(
        trailingText,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: colors.primary,
        ),
      ),
    );
  }

  // --- Creator & Developer Card ---
  Widget _buildCreatorCard(BuildContext context, AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: colors.borderSubtle == Colors.transparent
            ? null
            : Border.all(color: colors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.secondary, colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2.5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/Onkar_Proff.png',
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Image.asset(
                      'assets/onkar_proff.png',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx2, err2, stack2) => Icon(
                        Icons.person_rounded,
                        color: colors.primary,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Onkar Gaikwad',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textMain,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.purple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'IIT Gandhinagar',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: colors.purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Developer · AI Student',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Hey! I'm Onkar 👋 AI student at IIT Gandhinagar who loves building apps, experimenting with AI, and turning random ideas into actual projects.",
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          // "About Developer & Full Story" Button
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutDeveloperScreen()),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.badge_outlined, size: 16, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'About Developer & Full Story',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: colors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Links: GitHub, Portfolio, LinkedIn
          Row(
            children: [
              Expanded(
                child: _buildCreatorLinkBtn(
                  context: context,
                  colors: colors,
                  icon: Icons.code_rounded,
                  label: 'GitHub',
                  url: 'https://github.com/astronkar',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCreatorLinkBtn(
                  context: context,
                  colors: colors,
                  icon: Icons.language_rounded,
                  label: 'Portfolio',
                  url: 'https://astronkar.in',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCreatorLinkBtn(
                  context: context,
                  colors: colors,
                  icon: Icons.work_outline_rounded,
                  label: 'LinkedIn',
                  url: 'https://www.linkedin.com/in/onk4r/',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorLinkBtn({
    required BuildContext context,
    required AppColors colors,
    required IconData icon,
    required String label,
    required String url,
  }) {
    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        final uri = Uri.parse(url);
        try {
          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!launched && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open $url')),
            );
          }
        } catch (e) {
          debugPrint('Could not launch $url: $e');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: colors.borderSubtle == Colors.transparent
              ? null
              : Border.all(color: colors.borderSubtle, width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: colors.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: colors.textMain,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_outward_rounded, size: 12, color: colors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(AppColors colors) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      color: colors.borderSubtle == Colors.transparent
          ? colors.surface2.withValues(alpha: 0.4)
          : colors.borderSubtle,
    );
  }
}

/// Dedicated card for Aurex AI voice settings (Female / Male voice toggle + sample preview)
class _VoiceAssistantSettingsCard extends StatefulWidget {
  final AppColors colors;
  const _VoiceAssistantSettingsCard({required this.colors});

  @override
  State<_VoiceAssistantSettingsCard> createState() =>
      _VoiceAssistantSettingsCardState();
}

class _VoiceAssistantSettingsCardState
    extends State<_VoiceAssistantSettingsCard> {
  String _selectedGender = 'female';
  bool _isPlayingSample = false;

  @override
  void initState() {
    super.initState();
    _selectedGender = TtsService().currentGender;
  }

  Future<void> _switchGender(String gender) async {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedGender = gender;
    });
    await TtsService().setVoiceGender(gender);
  }

  Future<void> _testVoice() async {
    HapticFeedback.mediumImpact();
    setState(() => _isPlayingSample = true);
    await TtsService().speakSample();
    if (mounted) {
      setState(() => _isPlayingSample = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.borderSubtle == Colors.transparent
              ? (isDark ? Colors.white10 : Colors.black12)
              : colors.borderSubtle,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Assistant Voice',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colors.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select male or female neural voice persona',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Voice Selector Options: 2x2 grid with Studio Natural, British Elegance, Indian Male, and Indian Female
          Row(
            children: [
              Expanded(
                child: _buildVoiceOption(
                  title: 'Studio Female',
                  subtitle: 'Natural & Fluid',
                  icon: Icons.auto_awesome_rounded,
                  gender: 'female',
                  isSelected: _selectedGender == 'female',
                  colors: colors,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildVoiceOption(
                  title: 'British Female',
                  subtitle: 'Refined & Articulate',
                  icon: Icons.face_3_rounded,
                  gender: 'female_british',
                  isSelected: _selectedGender == 'female_british',
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildVoiceOption(
                  title: 'Indian Male',
                  subtitle: 'Deep & Confident',
                  icon: Icons.male_rounded,
                  gender: 'male',
                  isSelected: _selectedGender == 'male',
                  colors: colors,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildVoiceOption(
                  title: 'Indian Female',
                  subtitle: 'Warm & Melodic',
                  icon: Icons.female_rounded,
                  gender: 'female_indian',
                  isSelected: _selectedGender == 'female_indian',
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Listen Sample Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _testVoice,
              icon: Icon(
                _isPlayingSample
                    ? Icons.graphic_eq_rounded
                    : Icons.volume_up_rounded,
                size: 18,
                color: colors.primary,
              ),
              label: Text(
                _isPlayingSample
                    ? 'Speaking Sample...'
                    : 'Preview Selected Voice',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.primary.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String gender,
    required bool isSelected,
    required AppColors colors,
  }) {
    return InkWell(
      onTap: () => _switchGender(gender),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.12)
              : colors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? colors.primary : colors.textMuted,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? colors.primary : colors.textMain,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: isSelected
                    ? colors.primary.withValues(alpha: 0.8)
                    : colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/add_transaction_dialog.dart';
import '../../widgets/ai_assistant_sheet.dart';
import '../../widgets/brain_icon.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/profile_dialog.dart';
import '../../widgets/user_avatar.dart';
import '../auth/login_screen.dart';
import 'analytics_tab.dart';
import 'budget_tab.dart';
import 'overview_tab.dart';
import 'transactions_tab.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().fetchData();
    });
  }

  void _openAddTransaction() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionDialog(),
    );
  }

  void _openAIAssistant() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AIAssistantSheet(),
    );
  }

  void _openProfile() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (_) => const ProfileDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final appProvider = context.watch<AppProvider>();
    final authProvider = context.watch<AuthProvider>();

    // If user signed out, navigate to Login
    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
    }

    final profile = appProvider.userProfile ?? authProvider.userProfile;
    final initials = profile?.initials ?? 'U';
    final avatarUrl = profile?.avatarUrl ??
        authProvider.currentUser?.userMetadata?['avatar_url']?.toString() ??
        authProvider.currentUser?.userMetadata?['picture']?.toString();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: true,
        elevation: 0,
        backgroundColor: appProvider.isDarkMode
            ? colors.background
            : colors.surface.withValues(alpha: 0.85),
        shape: appProvider.isDarkMode
            ? null
            : Border(
                bottom: BorderSide(
                  color: colors.borderSubtle,
                  width: 0.8,
                ),
              ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: colors.primary,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/icon.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        leadingWidth: 52,
        title: Text(
          'SmartSpend',
          style: AppTheme.brandStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: colors.textMain,
          ),
        ),
        actions: [
          // Aurex AI Assistant Button in AppBar
          IconButton(
            tooltip: 'Aurex AI Assistant',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: BorderRadius.circular(10),
                border: appProvider.isDarkMode
                    ? null
                    : Border.all(
                        color: colors.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
              ),
              child: BrainIcon(
                color: colors.primary,
                size: 20,
              ),
            ),
            onPressed: _openAIAssistant,
          ),

          // Profile Button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: _openProfile,
              borderRadius: BorderRadius.circular(20),
              child: UserAvatar(
                avatarUrl: avatarUrl,
                initials: initials,
                size: 34,
                borderWidth: 1.5,
                borderColor: colors.borderSubtle,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                RepaintBoundary(
                  child: OverviewTab(
                    onNavigateToTransactions: () {
                      HapticFeedback.selectionClick();
                      setState(() => _currentIndex = 1);
                    },
                  ),
                ),
                const RepaintBoundary(child: TransactionsTab()),
                const RepaintBoundary(child: BudgetTab()),
                const RepaintBoundary(child: AnalyticsTab()),
              ],
            ),
          ),
        ],
      ),
      // Single Clean Add Transaction FAB (elevation 0, no drop shadows)
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_transaction_fab',
        onPressed: _openAddTransaction,
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: appProvider.isDarkMode
              ? null
              : Border(
                  top: BorderSide(color: colors.borderSubtle, width: 0.5),
                ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: colors.surface,
          indicatorColor: colors.primarySoft,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (idx) {
            if (_currentIndex != idx) {
              HapticFeedback.selectionClick();
              setState(() => _currentIndex = idx);
            }
          },
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: colors.textMuted),
              selectedIcon:
                  Icon(Icons.dashboard_rounded, color: colors.primary),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined, color: colors.textMuted),
              selectedIcon:
                  Icon(Icons.receipt_long_rounded, color: colors.primary),
              label: 'Transactions',
            ),
            NavigationDestination(
              icon: Icon(Icons.savings_outlined, color: colors.textMuted),
              selectedIcon:
                  Icon(Icons.savings_rounded, color: colors.primary),
              label: 'Budget',
            ),
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline_rounded,
                  color: colors.textMuted),
              selectedIcon:
                  Icon(Icons.pie_chart_rounded, color: colors.primary),
              label: 'Analytics',
            ),
          ],
        ),
      ),
    );
  }
}

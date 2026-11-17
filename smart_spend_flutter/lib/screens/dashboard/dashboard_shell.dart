import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/add_transaction_dialog.dart';
import '../../widgets/ai_assistant_sheet.dart';
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionDialog(),
    );
  }

  void _openAIAssistant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AIAssistantSheet(),
    );
  }

  void _openProfile() {
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
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
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
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'SmartSpend',
              style: AppTheme.brandStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: colors.textMain,
              ),
            ),
          ],
        ),
        actions: [
          // Aurex AI Assistant Button in AppBar
          IconButton(
            tooltip: 'Aurex AI Assistant',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: colors.primary,
                size: 18,
              ),
            ),
            onPressed: _openAIAssistant,
          ),

          // Theme Toggle Button
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              appProvider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: colors.textMain,
              size: 20,
            ),
            onPressed: () => appProvider.toggleTheme(),
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
                OverviewTab(
                  onNavigateToTransactions: () {
                    setState(() => _currentIndex = 1);
                  },
                ),
                const TransactionsTab(),
                const BudgetTab(),
                const AnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
      // Single Clean Add Transaction FAB
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_transaction_fab',
        onPressed: _openAddTransaction,
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            top: BorderSide(color: colors.borderSubtle, width: 0.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: colors.surface,
          indicatorColor: colors.primarySoft,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
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

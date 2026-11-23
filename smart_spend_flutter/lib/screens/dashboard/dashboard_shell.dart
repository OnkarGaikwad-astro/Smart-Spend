import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/widget_sync_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/add_transaction_dialog.dart';
import '../../widgets/ai_assistant_sheet.dart';
import '../../widgets/brain_icon.dart';
import '../../widgets/debt_dialogs.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/profile_dialog.dart';
import '../../widgets/user_avatar.dart';
import '../auth/login_screen.dart';
import 'analytics_tab.dart';
import 'budget_tab.dart';
import 'debts_tab.dart';
import 'overview_tab.dart';
import 'transactions_tab.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _currentIndex = 0;
  StreamSubscription<Uri>? _widgetLaunchSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().fetchData();
      final pending = WidgetSyncService().consumePendingUri();
      if (pending != null) {
        _handleWidgetUri(pending);
      }
    });

    WidgetSyncService().init();
    _widgetLaunchSub =
        WidgetSyncService().launchUriStream.listen(_handleWidgetUri);
  }

  @override
  void dispose() {
    _widgetLaunchSub?.cancel();
    super.dispose();
  }

  bool _isModalOpen = false;

  void _handleWidgetUri(Uri uri) {
    if (_isModalOpen) {
      debugPrint('[DashboardShell] Modal already open, ignoring duplicate URI: $uri');
      return;
    }
    final host = uri.host;
    final path = uri.path;
    final full = uri.toString();
    debugPrint('[DashboardShell] Handling widget URI: $uri (host: $host, path: $path)');

    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted || _isModalOpen) return;
      if (host == 'add-expense' || path.contains('add-expense') || full.contains('add-expense')) {
        _openAddTransaction(initialType: 'EXPENSE');
      } else if (host == 'add-income' || path.contains('add-income') || full.contains('add-income')) {
        _openAddTransaction(initialType: 'INCOME');
      } else if (host == 'add-debt' || path.contains('add-debt') || full.contains('add-debt')) {
        setState(() => _currentIndex = 2);
        final initialType = full.contains('borrowed') ? 'BORROWED' : 'LENT';
        _openAddDebt(initialType: initialType);
      } else if (host == 'debts' || path.contains('debts') || full.contains('debts')) {
        setState(() => _currentIndex = 2);
      } else if (host == 'dashboard' || path.contains('dashboard') || full.contains('dashboard')) {
        setState(() => _currentIndex = 0);
      }
    });
  }

  void _openAddTransaction({String initialType = 'EXPENSE'}) {
    if (_isModalOpen) return;
    _isModalOpen = true;
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionDialog(initialType: initialType),
    ).whenComplete(() {
      _isModalOpen = false;
    });
  }

  void _openAddDebt({String initialType = 'LENT'}) {
    if (_isModalOpen) return;
    _isModalOpen = true;
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPersonDebtDialog(initialType: initialType),
    ).whenComplete(() {
      _isModalOpen = false;
    });
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
                    onNavigateToLent: () {
                      HapticFeedback.selectionClick();
                      setState(() => _currentIndex = 2);
                    },
                  ),
                ),
                const RepaintBoundary(child: TransactionsTab()),
                const RepaintBoundary(child: DebtsTab()),
                const RepaintBoundary(child: BudgetTab()),
                const RepaintBoundary(child: AnalyticsTab()),
              ],
            ),
          ),
        ],
      ),
      // Clean Context-Aware Floating Action Button
      floatingActionButton: _currentIndex == 2
          ? FloatingActionButton.extended(
              heroTag: 'add_debt_fab',
              onPressed: () {
                HapticFeedback.mediumImpact();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AddPersonDebtDialog(),
                );
              },
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Lend / Borrow',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : (_currentIndex == 0 || _currentIndex == 1)
              ? FloatingActionButton(
                  heroTag: 'add_transaction_fab',
                  onPressed: _openAddTransaction,
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.add_rounded, size: 28),
                )
              : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: appProvider.isDarkMode
              ? null
              : Border(
                  top: BorderSide(color: colors.borderSubtle, width: 0.5),
                ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 64,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? colors.primary : colors.textMuted,
                letterSpacing: -0.2,
              );
            }),
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
                label: 'History',
              ),
              NavigationDestination(
                icon: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        Icons.handshake_rounded,
                        color: colors.primary,
                        size: 18,
                      ),
                    ),
                    if (appProvider.activeDebtsCount > 0)
                      Positioned(
                        top: -1,
                        right: -1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF5350),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                selectedIcon: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.40),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.handshake_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    if (appProvider.activeDebtsCount > 0)
                      Positioned(
                        top: -1,
                        right: -1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF5350),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Debts',
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
      ),
    );
  }
}

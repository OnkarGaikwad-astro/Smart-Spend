import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';

class WidgetSyncService {
  static final WidgetSyncService _instance = WidgetSyncService._internal();
  factory WidgetSyncService() => _instance;
  WidgetSyncService._internal();

  final _currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  final _launchStreamController = StreamController<Uri>.broadcast();
  Stream<Uri> get launchUriStream => _launchStreamController.stream;

  final _appLinks = AppLinks();

  Uri? _pendingLaunchUri;
  Uri? consumePendingUri() {
    final uri = _pendingLaunchUri;
    _pendingLaunchUri = null;
    return uri;
  }

  bool _isInitialized = false;
  DateTime? _lastDispatchedTime;
  String? _lastDispatchedUri;

  void _dispatchUri(Uri uri) {
    final now = DateTime.now();
    final uriStr = uri.toString();
    // Prevent duplicate triggers within 1.5 seconds
    if (_lastDispatchedUri == uriStr &&
        _lastDispatchedTime != null &&
        now.difference(_lastDispatchedTime!) < const Duration(milliseconds: 1500)) {
      debugPrint('[WidgetSync] Dropping duplicate launch URI: $uri');
      return;
    }
    _lastDispatchedTime = now;
    _lastDispatchedUri = uriStr;
    _pendingLaunchUri = uri;
    _launchStreamController.add(uri);
  }

  void init() {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Listen for HomeWidget clicks
    HomeWidget.widgetClicked.listen((Uri? uri) {
      if (uri != null) {
        debugPrint('[WidgetSync] HomeWidget clicked with URI: $uri');
        _dispatchUri(uri);
      }
    });

    HomeWidget.initiallyLaunchedFromHomeWidget().then((Uri? uri) {
      if (uri != null) {
        debugPrint('[WidgetSync] Initially launched from HomeWidget with URI: $uri');
        _dispatchUri(uri);
      }
    });

    // 2. Listen for deep link intents (app_links) from widget PendingIntents
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null && uri.scheme == 'smartspend') {
        debugPrint('[WidgetSync] AppLink stream received: $uri');
        _dispatchUri(uri);
      }
    });

    _appLinks.getInitialLink().then((Uri? uri) {
      if (uri != null && uri.scheme == 'smartspend') {
        debugPrint('[WidgetSync] Initial AppLink received: $uri');
        _dispatchUri(uri);
      }
    });
  }

  /// Syncs current app state and totals to native home screen widgets
  Future<void> updateWidgets(AppProvider provider) async {
    try {
      final totalBalance = provider.totalBalance;
      final monthlyIncome = provider.totalIncome;
      final monthlyExpenses = provider.totalExpense;

      final totalLent = provider.totalLentPending;
      final totalBorrowed = provider.totalBorrowedPending;
      final netDebt = provider.netDebtsBalance;
      final activeDebts = provider.activeDebtsCount;

      // 1. Quick Transactions Widget Data
      await HomeWidget.saveWidgetData<String>(
        'total_balance',
        _currencyFormat.format(totalBalance),
      );
      await HomeWidget.saveWidgetData<String>(
        'monthly_income',
        _currencyFormat.format(monthlyIncome),
      );
      await HomeWidget.saveWidgetData<String>(
        'monthly_expense',
        _currencyFormat.format(monthlyExpenses),
      );

      // 2. Debts & Khata Widget Data
      await HomeWidget.saveWidgetData<String>(
        'debts_total_lent',
        _currencyFormat.format(totalLent),
      );
      await HomeWidget.saveWidgetData<String>(
        'debts_total_borrowed',
        _currencyFormat.format(totalBorrowed),
      );
      final netSign = netDebt >= 0 ? '+' : '';
      await HomeWidget.saveWidgetData<String>(
        'debts_net_balance',
        '$netSign${_currencyFormat.format(netDebt)}',
      );
      await HomeWidget.saveWidgetData<String>(
        'debts_active_count',
        '$activeDebts active',
      );

      // Request Android to update both widgets
      await HomeWidget.updateWidget(
        name: 'QuickTransactionWidgetProvider',
        androidName: 'QuickTransactionWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: 'DebtsWidgetProvider',
        androidName: 'DebtsWidgetProvider',
      );

      debugPrint('[WidgetSync] Native widgets successfully updated.');
    } catch (e) {
      debugPrint('[WidgetSync] Non-fatal error updating widgets: $e');
    }
  }
}

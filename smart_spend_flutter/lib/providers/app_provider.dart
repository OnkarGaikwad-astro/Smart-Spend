import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/user_profile_model.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';

class AppProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final SyncService _syncService = SyncService();
  final Uuid _uuid = const Uuid();

  List<TransactionModel> _transactions = [];
  List<BudgetModel> _budgets = [];
  List<GoalModel> _goals = [];
  UserProfileModel? _userProfile;
  bool _isLoading = false;
  bool _isDarkMode = false;

  List<TransactionModel> get transactions => _transactions;
  List<BudgetModel> get budgets => _budgets;
  List<GoalModel> get goals => _goals;
  UserProfileModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  bool get isOnline => _syncService.isOnline;
  bool get isSyncing => _syncService.isSyncing;
  int get pendingSyncCount => _storage.pendingSyncCount;

  AppProvider() {
    _isDarkMode = _storage.isDarkMode();
    _loadFromLocal();

    // Listen to sync notifications
    _syncService.isOnlineNotifier.addListener(_onSyncStatusChanged);
    _syncService.isSyncingNotifier.addListener(_onSyncStatusChanged);
    _syncService.pendingCountNotifier.addListener(_onSyncStatusChanged);
  }

  void _onSyncStatusChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _syncService.isOnlineNotifier.removeListener(_onSyncStatusChanged);
    _syncService.isSyncingNotifier.removeListener(_onSyncStatusChanged);
    _syncService.pendingCountNotifier.removeListener(_onSyncStatusChanged);
    super.dispose();
  }

  void _loadFromLocal() {
    _transactions = _storage.getAllTransactions();
    _budgets = _storage.getAllBudgets();
    _goals = _storage.getAllGoals();
    _userProfile = _storage.getUserProfile();
    notifyListeners();
  }

  String? get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? _userProfile?.id;

  // --- Fetch Data (Local First, then Remote Pull) ---
  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();

    // 1. Immediately read from local Hive
    _loadFromLocal();

    // 2. If online, sync pending queue and pull remote updates
    if (_syncService.isOnline && _currentUserId != null) {
      try {
        await _syncService.syncAll();
        _loadFromLocal();
      } catch (e) {
        debugPrint('[AppProvider] Sync error: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- Transactions ---
  Future<void> addTransaction({
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    required String type,
    String? icon,
  }) async {
    final txn = TransactionModel(
      id: _uuid.v4(),
      userId: _currentUserId,
      title: title,
      category: category,
      amount: amount,
      date: date,
      type: type,
      icon: icon ?? category,
      createdAt: DateTime.now(),
    );

    // 1. Save locally (instant UI update)
    _transactions.insert(0, txn);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    await _storage.saveTransaction(txn);
    notifyListeners();

    // 2. Enqueue for remote sync
    await _syncService.enqueueInsert(
      table: 'transactions',
      recordId: txn.id,
      data: txn.toRemoteMap(currentUserId: _currentUserId),
    );
  }

  Future<void> updateTransaction(String id, {
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    required String type,
    String? icon,
  }) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final updatedTxn = _transactions[index].copyWith(
      title: title,
      category: category,
      amount: amount,
      date: date,
      type: type,
      icon: icon ?? category,
    );

    _transactions[index] = updatedTxn;
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    await _storage.saveTransaction(updatedTxn);
    notifyListeners();

    await _syncService.enqueueUpdate(
      table: 'transactions',
      recordId: id,
      data: updatedTxn.toRemoteMap(currentUserId: _currentUserId),
    );
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    await _storage.deleteTransaction(id);
    notifyListeners();

    await _syncService.enqueueDelete(
      table: 'transactions',
      recordId: id,
    );
  }

  // --- Budgets ---
  Future<void> addBudget({
    required String category,
    required double allocated,
    required String icon,
    String color = 'primary',
  }) async {
    final budget = BudgetModel(
      id: _uuid.v4(),
      userId: _currentUserId,
      category: category,
      allocated: allocated,
      spent: 0,
      icon: icon,
      color: color,
      createdAt: DateTime.now(),
    );

    _budgets.add(budget);
    await _storage.saveBudget(budget);
    notifyListeners();

    await _syncService.enqueueInsert(
      table: 'budgets',
      recordId: budget.id,
      data: budget.toRemoteMap(currentUserId: _currentUserId),
    );
  }

  Future<void> updateBudget(String id, {
    required String category,
    required double allocated,
    required String icon,
    String color = 'primary',
  }) async {
    final index = _budgets.indexWhere((b) => b.id == id);
    if (index == -1) return;

    final updated = _budgets[index].copyWith(
      category: category,
      allocated: allocated,
      icon: icon,
      color: color,
    );

    _budgets[index] = updated;
    await _storage.saveBudget(updated);
    notifyListeners();

    await _syncService.enqueueUpdate(
      table: 'budgets',
      recordId: id,
      data: updated.toRemoteMap(currentUserId: _currentUserId),
    );
  }

  Future<void> deleteBudget(String id) async {
    _budgets.removeWhere((b) => b.id == id);
    await _storage.deleteBudget(id);
    notifyListeners();

    await _syncService.enqueueDelete(
      table: 'budgets',
      recordId: id,
    );
  }

  // --- Goals ---
  Future<void> addGoal({
    required String name,
    required double target,
    required String targetDate,
    String color = 'primary',
  }) async {
    final goal = GoalModel(
      id: _uuid.v4(),
      userId: _currentUserId,
      name: name,
      target: target,
      saved: 0,
      targetDate: targetDate,
      color: color,
      createdAt: DateTime.now(),
    );

    _goals.add(goal);
    await _storage.saveGoal(goal);
    notifyListeners();

    await _syncService.enqueueInsert(
      table: 'goals',
      recordId: goal.id,
      data: goal.toRemoteMap(currentUserId: _currentUserId),
    );
  }

  Future<void> updateGoal(String id, {
    required String name,
    required double target,
    required String targetDate,
    String color = 'primary',
  }) async {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index == -1) return;

    final updated = _goals[index].copyWith(
      name: name,
      target: target,
      targetDate: targetDate,
      color: color,
    );

    _goals[index] = updated;
    await _storage.saveGoal(updated);
    notifyListeners();

    await _syncService.enqueueUpdate(
      table: 'goals',
      recordId: id,
      data: updated.toRemoteMap(currentUserId: _currentUserId),
    );
  }

  Future<void> deleteGoal(String id) async {
    _goals.removeWhere((g) => g.id == id);
    await _storage.deleteGoal(id);
    notifyListeners();

    await _syncService.enqueueDelete(
      table: 'goals',
      recordId: id,
    );
  }

  Future<void> depositToGoal(String id, double amount) async {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index == -1) return;

    final goal = _goals[index];
    final newSaved = goal.saved + amount;
    final updatedGoal = goal.copyWith(saved: newSaved);

    _goals[index] = updatedGoal;
    await _storage.saveGoal(updatedGoal);

    // Enqueue Goal Update
    await _syncService.enqueueUpdate(
      table: 'goals',
      recordId: id,
      data: {'saved': newSaved},
    );

    // Add EXPENSE transaction under Savings
    await addTransaction(
      title: 'Deposit to ${goal.name}',
      category: 'Savings',
      amount: -amount,
      type: 'EXPENSE',
      date: DateTime.now(),
      icon: 'savings',
    );
  }

  Future<void> sweepLeftover() async {
    final leftover = totalIncome - totalExpense;
    if (leftover <= 0 || _goals.isEmpty) return;

    final sweepPerGoal = (leftover / _goals.length).floorToDouble();
    if (sweepPerGoal <= 0) return;

    for (final goal in _goals) {
      await depositToGoal(goal.id, sweepPerGoal);
    }
  }

  // --- Profile ---
  Future<void> updateProfile({required String fullName}) async {
    if (_userProfile == null) return;

    final updated = _userProfile!.copyWith(fullName: fullName);
    _userProfile = updated;
    await _storage.saveUserProfile(updated);
    notifyListeners();

    await _syncService.enqueueUpdate(
      table: 'profiles',
      recordId: updated.id,
      data: {'full_name': fullName},
    );
  }

  // --- Theme ---
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _storage.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  // --- Computed Metrics ---
  double get totalIncome => _transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount.abs());

  double get totalBalance => totalIncome - totalExpense;

  int get savingsRate => totalIncome > 0
      ? (((totalIncome - totalExpense) / totalIncome) * 100).round()
      : 0;

  List<TransactionModel> get recentTransactions =>
      _transactions.take(5).toList();

  /// Dynamically computes spent for each budget based on actual expenses in current month
  List<BudgetModel> get computedBudgets {
    final now = DateTime.now();
    return _budgets.map((b) {
      final spent = _transactions
          .where((t) =>
              t.isExpense &&
              t.category.toLowerCase() == b.category.toLowerCase() &&
              t.date.month == now.month &&
              t.date.year == now.year)
          .fold(0.0, (sum, t) => sum + t.amount.abs());
      return b.copyWith(spent: spent);
    }).toList();
  }

  double get totalBudgetAllocated =>
      computedBudgets.fold(0.0, (sum, b) => sum + b.allocated);

  double get totalBudgetSpent =>
      computedBudgets.fold(0.0, (sum, b) => sum + b.spent);

  int get budgetUtilizationPercentage => totalBudgetAllocated > 0
      ? ((totalBudgetSpent / totalBudgetAllocated) * 100).clamp(0, 100).round()
      : 0;
}

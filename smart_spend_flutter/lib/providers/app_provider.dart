import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/debt_model.dart';
import '../models/user_profile_model.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../services/widget_sync_service.dart';

class AppProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final SyncService _syncService = SyncService();
  final Uuid _uuid = const Uuid();

  List<TransactionModel> _transactions = [];
  List<BudgetModel> _budgets = [];
  List<GoalModel> _goals = [];
  List<DebtModel> _debts = [];
  UserProfileModel? _userProfile;
  bool _isLoading = false;
  bool _isDarkMode = true;

  List<TransactionModel> get transactions => _transactions;
  List<BudgetModel> get budgets => _budgets;
  List<GoalModel> get goals => _goals;
  List<DebtModel> get debts => _debts;
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
  void notifyListeners() {
    super.notifyListeners();
    WidgetSyncService().updateWidgets(this);
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
    _debts = _storage.getAllDebts();
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

  Future<void> syncNow() async {
    if (_syncService.isOnline) {
      await _syncService.syncAll();
      _loadFromLocal();
      notifyListeners();
    }
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

  // --- Debts (Lent to Friends & Borrowed from Others) ---
  /// Total money others owe you (You'll Get)
  double get totalLentPending =>
      _debts.where((d) => d.isLent).fold(0.0, (sum, d) => sum + d.totalOwed);

  /// Total money you owe to others (You'll Give)
  double get totalBorrowedPending =>
      _debts.where((d) => d.isBorrowed).fold(0.0, (sum, d) => sum + d.totalOwed);

  /// Net balance (+ if you are owed more, - if you owe more)
  double get netDebtsBalance => totalLentPending - totalBorrowedPending;

  /// Total money recovered from people who borrowed from you
  double get totalLentRecovered =>
      _debts.where((d) => d.isLent).fold(0.0, (sum, d) => sum + d.totalRepaid);

  /// Total money repaid to people you borrowed from
  double get totalBorrowedRepaid =>
      _debts.where((d) => d.isBorrowed).fold(0.0, (sum, d) => sum + d.totalRepaid);

  int get activeBorrowersCount =>
      _debts.where((d) => !d.isSettled).length;

  int get activeDebtsCount =>
      _debts.where((d) => !d.isSettled).length;

  int get activeLentCount =>
      _debts.where((d) => d.isLent && !d.isSettled).length;

  int get activeBorrowedCount =>
      _debts.where((d) => d.isBorrowed && !d.isSettled).length;

  Future<void> addDebtPerson({
    required String personName,
    String? phoneNumber,
    required double initialAmount,
    required String note,
    DateTime? date,
    String type = 'LENT', // 'LENT' (They owe me) or 'BORROWED' (I owe them)
  }) async {
    final entryDate = date ?? DateTime.now();
    final debtId = _uuid.v4();
    final entryType = type.toUpperCase() == 'BORROWED' ? 'BORROWED' : 'LENT';

    final firstEntry = DebtEntry(
      id: _uuid.v4(),
      debtId: debtId,
      amount: initialAmount.abs(),
      type: entryType,
      note: note.trim().isEmpty
          ? (entryType == 'BORROWED' ? 'Borrowed money' : 'Lent money')
          : note.trim(),
      date: entryDate,
    );

    final debt = DebtModel(
      id: debtId,
      userId: _currentUserId,
      personName: personName.trim(),
      phoneNumber: phoneNumber?.trim(),
      type: entryType,
      entries: [firstEntry],
      createdAt: entryDate,
      updatedAt: entryDate,
    );

    _debts.insert(0, debt);
    await _storage.saveDebt(debt);
    notifyListeners();

    // Enqueue cloud sync to Supabase
    await _syncService.enqueueInsert(
      table: 'debts',
      recordId: debt.id,
      data: debt.toRemoteMap(currentUserId: _currentUserId),
    );
    await _syncService.enqueueInsert(
      table: 'debt_entries',
      recordId: firstEntry.id,
      data: firstEntry.toRemoteMap(currentUserId: _currentUserId),
    );
  }

  Future<void> addMoreToDebt({
    required String debtId,
    required double amount,
    required String note,
    DateTime? date,
  }) async {
    final index = _debts.indexWhere((d) => d.id == debtId);
    if (index == -1) return;

    final current = _debts[index];
    final entryDate = date ?? DateTime.now();
    final entryType = current.isBorrowed ? 'BORROWED' : 'LENT';

    final newEntry = DebtEntry(
      id: _uuid.v4(),
      debtId: debtId,
      amount: amount.abs(),
      type: entryType,
      note: note.trim().isEmpty
          ? (current.isBorrowed ? 'Borrowed more' : 'Lent more')
          : note.trim(),
      date: entryDate,
    );

    final updatedEntries = List<DebtEntry>.from(current.entries)..add(newEntry);
    final updatedDebt = current.copyWith(
      entries: updatedEntries,
      updatedAt: DateTime.now(),
    );

    _debts[index] = updatedDebt;
    _debts.sort((a, b) => b.lastActivityDate.compareTo(a.lastActivityDate));
    await _storage.saveDebt(updatedDebt);
    notifyListeners();

    // Enqueue cloud sync
    await _syncService.enqueueInsert(
      table: 'debt_entries',
      recordId: newEntry.id,
      data: newEntry.toRemoteMap(currentUserId: _currentUserId),
    );
    await _syncService.enqueueUpdate(
      table: 'debts',
      recordId: debtId,
      data: {'updated_at': updatedDebt.updatedAt.toIso8601String()},
    );
  }

  Future<void> recordDebtRepayment({
    required String debtId,
    required double amount,
    required String note,
    DateTime? date,
  }) async {
    final index = _debts.indexWhere((d) => d.id == debtId);
    if (index == -1) return;

    final current = _debts[index];
    final entryDate = date ?? DateTime.now();
    final newEntry = DebtEntry(
      id: _uuid.v4(),
      debtId: debtId,
      amount: amount.abs(),
      type: 'REPAID',
      note: note.trim().isEmpty ? 'Repayment' : note.trim(),
      date: entryDate,
    );

    final updatedEntries = List<DebtEntry>.from(current.entries)..add(newEntry);
    final updatedDebt = current.copyWith(
      entries: updatedEntries,
      updatedAt: DateTime.now(),
    );

    _debts[index] = updatedDebt;
    _debts.sort((a, b) => b.lastActivityDate.compareTo(a.lastActivityDate));
    await _storage.saveDebt(updatedDebt);
    notifyListeners();

    // Enqueue cloud sync
    await _syncService.enqueueInsert(
      table: 'debt_entries',
      recordId: newEntry.id,
      data: newEntry.toRemoteMap(currentUserId: _currentUserId),
    );
    await _syncService.enqueueUpdate(
      table: 'debts',
      recordId: debtId,
      data: {'updated_at': updatedDebt.updatedAt.toIso8601String()},
    );
  }

  Future<void> settleDebt(String debtId) async {
    final index = _debts.indexWhere((d) => d.id == debtId);
    if (index == -1) return;

    final current = _debts[index];
    if (current.totalOwed <= 0) return;

    final settleEntry = DebtEntry(
      id: _uuid.v4(),
      debtId: debtId,
      amount: current.totalOwed,
      type: 'REPAID',
      note: 'Settled in full',
      date: DateTime.now(),
    );

    final updatedEntries = List<DebtEntry>.from(current.entries)..add(settleEntry);
    final updatedDebt = current.copyWith(
      entries: updatedEntries,
      updatedAt: DateTime.now(),
    );

    _debts[index] = updatedDebt;
    await _storage.saveDebt(updatedDebt);
    notifyListeners();

    await _syncService.enqueueInsert(
      table: 'debt_entries',
      recordId: settleEntry.id,
      data: settleEntry.toRemoteMap(currentUserId: _currentUserId),
    );
    await _syncService.enqueueUpdate(
      table: 'debts',
      recordId: debtId,
      data: {'updated_at': updatedDebt.updatedAt.toIso8601String()},
    );
  }

  Future<void> deleteDebt(String debtId) async {
    _debts.removeWhere((d) => d.id == debtId);
    await _storage.deleteDebt(debtId);
    notifyListeners();

    await _syncService.enqueueDelete(
      table: 'debts',
      recordId: debtId,
    );
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

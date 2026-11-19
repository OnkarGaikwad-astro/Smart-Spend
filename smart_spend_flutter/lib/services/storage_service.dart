import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/user_profile_model.dart';
import '../models/sync_queue_item.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late Box _transactionsBox;
  late Box _budgetsBox;
  late Box _goalsBox;
  late Box _profileBox;
  late Box _syncQueueBox;
  late Box _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();

    _transactionsBox = await Hive.openBox(AppConstants.transactionsBox);
    _budgetsBox = await Hive.openBox(AppConstants.budgetsBox);
    _goalsBox = await Hive.openBox(AppConstants.goalsBox);
    _profileBox = await Hive.openBox(AppConstants.profileBox);
    _syncQueueBox = await Hive.openBox(AppConstants.syncQueueBox);
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);

    if (!_settingsBox.containsKey('dark_aesthetic_applied_v3')) {
      await _settingsBox.put('dark_aesthetic_applied_v3', true);
      await _settingsBox.put('is_dark_mode', true);
    }
  }

  // --- Transactions ---
  List<TransactionModel> getAllTransactions() {
    final list = <TransactionModel>[];
    for (var key in _transactionsBox.keys) {
      final val = _transactionsBox.get(key);
      if (val is Map) {
        list.add(TransactionModel.fromMap(val));
      }
    }
    // Sort descending by date
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> saveTransaction(TransactionModel txn) async {
    await _transactionsBox.put(txn.id, txn.toMap());
  }

  Future<void> saveAllTransactions(List<TransactionModel> txns) async {
    final entries = {for (var t in txns) t.id: t.toMap()};
    await _transactionsBox.putAll(entries);
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionsBox.delete(id);
  }

  // --- Budgets ---
  List<BudgetModel> getAllBudgets() {
    final list = <BudgetModel>[];
    for (var key in _budgetsBox.keys) {
      final val = _budgetsBox.get(key);
      if (val is Map) {
        list.add(BudgetModel.fromMap(val));
      }
    }
    return list;
  }

  Future<void> saveBudget(BudgetModel budget) async {
    await _budgetsBox.put(budget.id, budget.toMap());
  }

  Future<void> saveAllBudgets(List<BudgetModel> budgets) async {
    final entries = {for (var b in budgets) b.id: b.toMap()};
    await _budgetsBox.putAll(entries);
  }

  Future<void> deleteBudget(String id) async {
    await _budgetsBox.delete(id);
  }

  // --- Goals ---
  List<GoalModel> getAllGoals() {
    final list = <GoalModel>[];
    for (var key in _goalsBox.keys) {
      final val = _goalsBox.get(key);
      if (val is Map) {
        list.add(GoalModel.fromMap(val));
      }
    }
    return list;
  }

  Future<void> saveGoal(GoalModel goal) async {
    await _goalsBox.put(goal.id, goal.toMap());
  }

  Future<void> saveAllGoals(List<GoalModel> goals) async {
    final entries = {for (var g in goals) g.id: g.toMap()};
    await _goalsBox.putAll(entries);
  }

  Future<void> deleteGoal(String id) async {
    await _goalsBox.delete(id);
  }

  // --- User Profile ---
  UserProfileModel? getUserProfile() {
    final val = _profileBox.get('current_profile');
    if (val is Map) {
      return UserProfileModel.fromMap(val);
    }
    return null;
  }

  Future<void> saveUserProfile(UserProfileModel profile) async {
    await _profileBox.put('current_profile', profile.toMap());
  }

  Future<void> clearUserProfile() async {
    await _profileBox.delete('current_profile');
  }

  // --- Sync Queue ---
  List<SyncQueueItem> getSyncQueue() {
    final list = <SyncQueueItem>[];
    for (var key in _syncQueueBox.keys) {
      final val = _syncQueueBox.get(key);
      if (val is Map) {
        list.add(SyncQueueItem.fromMap(val));
      }
    }
    // Sort ascending by creation time to process in order
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<void> addToSyncQueue(SyncQueueItem item) async {
    await _syncQueueBox.put(item.id, item.toMap());
  }

  Future<void> removeFromSyncQueue(String id) async {
    await _syncQueueBox.delete(id);
  }

  int get pendingSyncCount => _syncQueueBox.length;

  // --- Settings ---
  bool isDarkMode() {
    return _settingsBox.get('is_dark_mode', defaultValue: true) as bool;
  }

  Future<void> setDarkMode(bool isDark) async {
    await _settingsBox.put('dark_aesthetic_applied_v3', true);
    await _settingsBox.put('is_dark_mode', isDark);
  }

  Future<void> clearAll() async {
    await _transactionsBox.clear();
    await _budgetsBox.clear();
    await _goalsBox.clear();
    await _profileBox.clear();
    await _syncQueueBox.clear();
  }
}

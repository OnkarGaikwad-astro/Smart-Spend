import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/debt_model.dart';
import '../models/user_profile_model.dart';
import '../models/sync_queue_item.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late Box _transactionsBox;
  late Box _budgetsBox;
  late Box _goalsBox;
  late Box _debtsBox;
  late Box _profileBox;
  late Box _syncQueueBox;
  late Box _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();

    final boxes = await Future.wait([
      Hive.openBox(AppConstants.transactionsBox),
      Hive.openBox(AppConstants.budgetsBox),
      Hive.openBox(AppConstants.goalsBox),
      Hive.openBox(AppConstants.debtsBox),
      Hive.openBox(AppConstants.profileBox),
      Hive.openBox(AppConstants.syncQueueBox),
      Hive.openBox(AppConstants.settingsBox),
    ]);

    _transactionsBox = boxes[0];
    _budgetsBox = boxes[1];
    _goalsBox = boxes[2];
    _debtsBox = boxes[3];
    _profileBox = boxes[4];
    _syncQueueBox = boxes[5];
    _settingsBox = boxes[6];

    if (!_settingsBox.containsKey('dark_aesthetic_applied_v4')) {
      await _settingsBox.put('dark_aesthetic_applied_v4', true);
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

  Future<void> saveTransactions(List<TransactionModel> txns) async {
    final map = {for (var t in txns) t.id: t.toMap()};
    await _transactionsBox.putAll(map);
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

  Future<void> saveBudgets(List<BudgetModel> budgets) async {
    final map = {for (var b in budgets) b.id: b.toMap()};
    await _budgetsBox.putAll(map);
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

  Future<void> saveGoals(List<GoalModel> goals) async {
    final map = {for (var g in goals) g.id: g.toMap()};
    await _goalsBox.putAll(map);
  }

  Future<void> deleteGoal(String id) async {
    await _goalsBox.delete(id);
  }

  // --- Debts / Khata ---
  List<DebtModel> getAllDebts() {
    final list = <DebtModel>[];
    for (var key in _debtsBox.keys) {
      final val = _debtsBox.get(key);
      if (val is Map) {
        list.add(DebtModel.fromMap(val));
      }
    }
    // Sort descending by updated date
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Future<void> saveDebt(DebtModel debt) async {
    await _debtsBox.put(debt.id, debt.toMap());
  }

  Future<void> saveDebts(List<DebtModel> debts) async {
    final map = {for (var d in debts) d.id: d.toMap()};
    await _debtsBox.putAll(map);
  }

  Future<void> deleteDebt(String id) async {
    await _debtsBox.delete(id);
  }

  // --- Profile ---
  UserProfileModel? getUserProfile() {
    final val = _profileBox.get('current_user');
    if (val is Map) {
      return UserProfileModel.fromMap(val);
    }
    return null;
  }

  Future<void> saveUserProfile(UserProfileModel profile) async {
    await _profileBox.put('current_user', profile.toMap());
  }

  Future<void> clearUserProfile() async {
    await _profileBox.delete('current_user');
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

  // --- Settings & Preferences ---
  String getThemeModeString() {
    return _settingsBox.get('theme_mode', defaultValue: 'system') as String;
  }

  Future<void> setThemeModeString(String mode) async {
    await _settingsBox.put('theme_mode', mode);
    await _settingsBox.put('is_dark_mode', mode == 'dark');
  }

  bool isDarkMode() {
    final mode = getThemeModeString();
    if (mode == 'system') {
      return _settingsBox.get('is_dark_mode', defaultValue: true) as bool;
    }
    return mode == 'dark';
  }

  Future<void> setDarkMode(bool isDark) async {
    await _settingsBox.put('dark_aesthetic_applied_v3', true);
    await _settingsBox.put('is_dark_mode', isDark);
    await _settingsBox.put('theme_mode', isDark ? 'dark' : 'light');
  }

  String getColorPalette() {
    return _settingsBox.get('color_palette', defaultValue: 'ocean') as String;
  }

  Future<void> setColorPalette(String palette) async {
    await _settingsBox.put('color_palette', palette);
  }

  String getCurrencySymbol() {
    return _settingsBox.get('currency_symbol', defaultValue: '₹') as String;
  }

  Future<void> setCurrencySymbol(String symbol) async {
    await _settingsBox.put('currency_symbol', symbol);
  }

  bool isHideBalances() {
    return false; // Privacy mode removed per user request
  }

  Future<void> setHideBalances(bool hide) async {
    await _settingsBox.put('hide_balances', false);
  }

  // --- Extended Preferences ---
  String getDefaultPaymentMode() {
    return _settingsBox.get('default_payment_mode', defaultValue: 'UPI') as String;
  }

  Future<void> setDefaultPaymentMode(String mode) async {
    await _settingsBox.put('default_payment_mode', mode);
  }

  String getDefaultCategory() {
    return _settingsBox.get('default_category', defaultValue: 'Food & Dining') as String;
  }

  Future<void> setDefaultCategory(String cat) async {
    await _settingsBox.put('default_category', cat);
  }

  bool isAutoCategorizeEnabled() {
    return _settingsBox.get('smart_auto_categorize', defaultValue: true) as bool;
  }

  Future<void> setAutoCategorizeEnabled(bool enabled) async {
    await _settingsBox.put('smart_auto_categorize', enabled);
  }

  bool isShowDecimalsEnabled() {
    return _settingsBox.get('show_decimals', defaultValue: false) as bool;
  }

  Future<void> setShowDecimalsEnabled(bool enabled) async {
    await _settingsBox.put('show_decimals', enabled);
  }

  bool isWeekStartMonday() {
    return _settingsBox.get('week_start_monday', defaultValue: true) as bool;
  }

  Future<void> setWeekStartMonday(bool monday) async {
    await _settingsBox.put('week_start_monday', monday);
  }

  bool isAutoSpeakAiEnabled() {
    return _settingsBox.get('auto_speak_ai', defaultValue: true) as bool;
  }

  Future<void> setAutoSpeakAiEnabled(bool enabled) async {
    await _settingsBox.put('auto_speak_ai', enabled);
  }

  bool isSoundEffectsEnabled() {
    return _settingsBox.get('sound_effects_enabled', defaultValue: true) as bool;
  }

  Future<void> setSoundEffectsEnabled(bool enabled) async {
    await _settingsBox.put('sound_effects_enabled', enabled);
  }

  bool isHapticsEnabled() {
    return _settingsBox.get('haptics_enabled', defaultValue: true) as bool;
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    await _settingsBox.put('haptics_enabled', enabled);
  }

  bool isDailyReminderEnabled() {
    return _settingsBox.get('daily_reminder_enabled', defaultValue: true) as bool;
  }

  Future<void> setDailyReminderEnabled(bool enabled) async {
    await _settingsBox.put('daily_reminder_enabled', enabled);
  }

  bool isBudgetAlertsEnabled() {
    return _settingsBox.get('budget_alerts_enabled', defaultValue: true) as bool;
  }

  Future<void> setBudgetAlertsEnabled(bool enabled) async {
    await _settingsBox.put('budget_alerts_enabled', enabled);
  }

  bool isDebtRemindersEnabled() {
    return _settingsBox.get('debt_reminders_enabled', defaultValue: true) as bool;
  }

  Future<void> setDebtRemindersEnabled(bool enabled) async {
    await _settingsBox.put('debt_reminders_enabled', enabled);
  }

  // --- Custom Gemini API Key ---
  String? getCustomGeminiApiKey() => _settingsBox.get('custom_gemini_api_key');
  Future<void> setCustomGeminiApiKey(String? key) => _settingsBox.put('custom_gemini_api_key', key);

  Future<void> clearAll() async {
    await _transactionsBox.clear();
    await _budgetsBox.clear();
    await _goalsBox.clear();
    await _debtsBox.clear();
    await _profileBox.clear();
    await _syncQueueBox.clear();
  }
}

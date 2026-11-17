import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/sync_queue_item.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/user_profile_model.dart';
import 'storage_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final StorageService _storage = StorageService();
  final Connectivity _connectivity = Connectivity();
  final Uuid _uuid = const Uuid();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;
  bool _isSyncing = false;

  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> pendingCountNotifier = ValueNotifier<int>(0);

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;

  Future<void> init() async {
    // Check initial connectivity
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (_) {
      _isOnline = true;
      isOnlineNotifier.value = true;
    }

    pendingCountNotifier.value = _storage.pendingSyncCount;

    // Listen for connectivity changes
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      final wasOffline = !_isOnline;
      _updateConnectionStatus(results);

      // If we just came back online, automatically trigger queue sync and pull!
      if (wasOffline && _isOnline) {
        debugPrint('[SyncService] Connectivity restored. Triggering sync...');
        syncAll();
      }
    });
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final connected = results.isNotEmpty &&
        !results.contains(ConnectivityResult.none);
    _isOnline = connected;
    isOnlineNotifier.value = connected;
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  // --- Enqueue Operations ---
  Future<void> enqueueInsert({
    required String table,
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    final item = SyncQueueItem(
      id: _uuid.v4(),
      table: table,
      action: 'insert',
      recordId: recordId,
      data: data,
      createdAt: DateTime.now(),
    );
    await _storage.addToSyncQueue(item);
    pendingCountNotifier.value = _storage.pendingSyncCount;

    // Attempt to sync immediately if online
    if (_isOnline) {
      unawaited(syncPendingQueue());
    }
  }

  Future<void> enqueueUpdate({
    required String table,
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    final item = SyncQueueItem(
      id: _uuid.v4(),
      table: table,
      action: 'update',
      recordId: recordId,
      data: data,
      createdAt: DateTime.now(),
    );
    await _storage.addToSyncQueue(item);
    pendingCountNotifier.value = _storage.pendingSyncCount;

    if (_isOnline) {
      unawaited(syncPendingQueue());
    }
  }

  Future<void> enqueueDelete({
    required String table,
    required String recordId,
  }) async {
    final item = SyncQueueItem(
      id: _uuid.v4(),
      table: table,
      action: 'delete',
      recordId: recordId,
      data: {},
      createdAt: DateTime.now(),
    );
    await _storage.addToSyncQueue(item);
    pendingCountNotifier.value = _storage.pendingSyncCount;

    if (_isOnline) {
      unawaited(syncPendingQueue());
    }
  }

  // --- Flush / Process Sync Queue to Supabase ---
  Future<void> syncPendingQueue() async {
    if (_isSyncing || !_isOnline) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final queue = _storage.getSyncQueue();
    if (queue.isEmpty) {
      pendingCountNotifier.value = 0;
      return;
    }

    _isSyncing = true;
    isSyncingNotifier.value = true;

    try {
      for (final item in queue) {
        if (!_isOnline) break;

        try {
          final table = supabase.from(item.table);
          final data = Map<String, dynamic>.from(item.data);
          
          // Ensure user_id is set
          if (item.action != 'delete' && !data.containsKey('user_id') && item.table != 'profiles') {
            data['user_id'] = user.id;
          }

          if (item.action == 'insert') {
            await table.upsert(data);
          } else if (item.action == 'update') {
            await table.update(data).eq('id', item.recordId);
          } else if (item.action == 'delete') {
            await table.delete().eq('id', item.recordId);
          }

          // Successfully processed, remove from queue
          await _storage.removeFromSyncQueue(item.id);
        } catch (e) {
          debugPrint('[SyncService] Failed syncing item ${item.id} on table ${item.table}: $e');
          // If error is network or temporary, keep in queue to retry later
        }
      }
    } finally {
      _isSyncing = false;
      isSyncingNotifier.value = false;
      pendingCountNotifier.value = _storage.pendingSyncCount;
    }
  }

  // --- Pull Remote Data from Supabase ---
  Future<void> pullRemoteData() async {
    if (!_isOnline) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Fetch Profile
      try {
        final profileRes = await supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (profileRes != null) {
          final sessionAvatar = user.userMetadata?['avatar_url']?.toString() ??
              user.userMetadata?['picture']?.toString();
          final cached = _storage.getUserProfile();
          final profile = UserProfileModel(
            id: profileRes['id']?.toString() ?? user.id,
            email: profileRes['email']?.toString() ?? user.email ?? '',
            fullName: profileRes['full_name']?.toString() ??
                user.userMetadata?['full_name']?.toString() ??
                cached?.fullName,
            avatarUrl: profileRes['avatar_url']?.toString() ??
                sessionAvatar ??
                cached?.avatarUrl,
          );
          await _storage.saveUserProfile(profile);
        }
      } catch (e) {
        debugPrint('[SyncService] Profile pull error: $e');
      }

      // Check which IDs are currently queued for updates/deletes locally to avoid overwriting pending edits
      final queuedItems = _storage.getSyncQueue();
      final pendingTransactionIds = queuedItems
          .where((i) => i.table == 'transactions')
          .map((i) => i.recordId)
          .toSet();
      final pendingBudgetIds = queuedItems
          .where((i) => i.table == 'budgets')
          .map((i) => i.recordId)
          .toSet();
      final pendingGoalIds = queuedItems
          .where((i) => i.table == 'goals')
          .map((i) => i.recordId)
          .toSet();

      // 2. Fetch Transactions
      final txnsRes = await supabase
          .from('transactions')
          .select()
          .order('date', ascending: false);

      final remoteTxns = (txnsRes as List)
          .map((m) => TransactionModel.fromMap(m))
          .toList();

      for (var txn in remoteTxns) {
        if (!pendingTransactionIds.contains(txn.id)) {
          await _storage.saveTransaction(txn);
        }
      }

      // 3. Fetch Budgets
      final budgetsRes = await supabase.from('budgets').select();
      final remoteBudgets = (budgetsRes as List)
          .map((m) => BudgetModel.fromMap(m))
          .toList();

      for (var budget in remoteBudgets) {
        if (!pendingBudgetIds.contains(budget.id)) {
          await _storage.saveBudget(budget);
        }
      }

      // 4. Fetch Goals
      final goalsRes = await supabase.from('goals').select();
      final remoteGoals =
          (goalsRes as List).map((m) => GoalModel.fromMap(m)).toList();

      for (var goal in remoteGoals) {
        if (!pendingGoalIds.contains(goal.id)) {
          await _storage.saveGoal(goal);
        }
      }
    } catch (e) {
      debugPrint('[SyncService] Pull remote data error: $e');
    }
  }

  // --- Combined Full Sync ---
  Future<void> syncAll() async {
    await syncPendingQueue();
    await pullRemoteData();
  }
}

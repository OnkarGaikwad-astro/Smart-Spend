import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String reminderChannelId = 'smartspend_reminders';
  static const String reminderChannelName = 'Daily Logging Reminders';
  static const String alertsChannelId = 'smartspend_alerts';
  static const String alertsChannelName = 'Budget & Khata Alerts';

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('[NotificationService] Timezone init: $e');
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint(
            '[NotificationService] Notification tapped: ${response.payload}');
      },
    );

    // Create Android notification channels
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          reminderChannelId,
          reminderChannelName,
          description: 'Daily 9:00 PM reminder to log daily transactions',
          importance: Importance.high,
          enableVibration: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          alertsChannelId,
          alertsChannelName,
          description: 'Instant alerts for budget limits and khata repayments',
          importance: Importance.max,
          enableVibration: true,
        ),
      );
    }

    _isInitialized = true;
    debugPrint('[NotificationService] Initialized successfully');
  }

  Future<bool> requestPermission() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted =
          await androidPlugin.requestNotificationsPermission() ?? false;
      return granted;
    }

    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      return granted;
    }
    return true;
  }

  /// Send an immediate notification (useful for testing or instant events)
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = alertsChannelId,
    String channelName = alertsChannelName,
  }) async {
    if (!_isInitialized) await init();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Sends a verified test notification to prove notifications work
  Future<void> sendTestNotification() async {
    await showInstantNotification(
      id: 9999,
      title: '🔔 SmartSpend Notifications Active!',
      body:
          'Your daily expense reminders and intelligent budget alerts are now live.',
      payload: 'test_notification',
    );
  }

  /// Budget Alert Notification
  Future<void> showBudgetAlert({
    required String category,
    required double percent,
    required double currentSpent,
    required double budgetLimit,
    required String currencySymbol,
  }) async {
    final formattedSpent = currentSpent.toStringAsFixed(0);
    final formattedLimit = budgetLimit.toStringAsFixed(0);
    final isExceeded = percent >= 100;

    final title = isExceeded
        ? '🚨 Budget Exceeded: $category!'
        : '⚠️ Budget Warning: $category';

    final body = isExceeded
        ? 'You have exceeded your limit! Spent $currencySymbol$formattedSpent of $currencySymbol$formattedLimit (${percent.toStringAsFixed(0)}%).'
        : 'You have reached ${percent.toStringAsFixed(0)}% of your limit ($currencySymbol$formattedSpent / $currencySymbol$formattedLimit).';

    await showInstantNotification(
      id: category.hashCode.abs() % 10000,
      title: title,
      body: body,
      channelId: alertsChannelId,
      channelName: alertsChannelName,
      payload: 'budget_alert_$category',
    );
  }

  /// Khata / Debt Reminder
  Future<void> showKhataReminder({
    required String personName,
    required double amount,
    required String direction, // 'LENT' or 'BORROWED'
    required String currencySymbol,
  }) async {
    final title = direction == 'LENT'
        ? '🤝 Repayment Due: $personName'
        : '💳 Payment Reminder: $personName';

    final body = direction == 'LENT'
        ? '$personName owes you $currencySymbol${amount.toStringAsFixed(0)}. Send a gentle reminder!'
        : 'You owe $personName $currencySymbol${amount.toStringAsFixed(0)}. Tap to record settlement.';

    await showInstantNotification(
      id: personName.hashCode.abs() % 10000,
      title: title,
      body: body,
      channelId: alertsChannelId,
      channelName: alertsChannelName,
      payload: 'debt_reminder_$personName',
    );
  }

  /// Schedules daily 9:00 PM reminder
  Future<void> scheduleDailyReminder({
    int hour = 21,
    int minute = 0,
  }) async {
    if (!_isInitialized) await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final androidDetails = const AndroidNotificationDetails(
      reminderChannelId,
      reminderChannelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: 1001,
        title: '🌙 SmartSpend Daily Check-in',
        body:
            'Did you spend anything today? Log your transactions to keep your finances in check.',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint(
          '[NotificationService] Scheduled daily reminder for $hour:$minute');
    } catch (e) {
      debugPrint('[NotificationService] Schedule reminder warning: $e');
    }
  }

  Future<void> cancelDailyReminder() async {
    await _notificationsPlugin.cancel(id: 1001);
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}

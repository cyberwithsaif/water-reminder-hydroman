import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../data/models/reminder.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Called once at app startup
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data and set local timezone
    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
      debugPrint('NotificationService: Timezone set to ${tzInfo.identifier}');
    } catch (e) {
      debugPrint('NotificationService: Failed to get timezone: $e');
      // Fallback: use offset-based approach
      _setTimezoneFromOffset();
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );

    final settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel with custom sound
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      // Delete old channel that may have cached invalid sound settings
      await androidPlugin.deleteNotificationChannel('hydroman_reminders');

      final channel = AndroidNotificationChannel(
        'hydroman_reminders',
        'Water Reminders',
        description: 'Hydration reminder notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin.createNotificationChannel(channel);
    }

    _initialized = true;
    debugPrint('NotificationService: Initialized successfully');
  }

  /// Fallback timezone detection from UTC offset
  void _setTimezoneFromOffset() {
    final offset = DateTime.now().timeZoneOffset;
    // Map common offsets to timezone names
    final offsetMap = {
      const Duration(hours: 5, minutes: 30): 'Asia/Kolkata',
      const Duration(hours: 0): 'UTC',
      const Duration(hours: 1): 'Europe/London',
      const Duration(hours: 2): 'Europe/Berlin',
      const Duration(hours: 3): 'Europe/Moscow',
      const Duration(hours: 8): 'Asia/Shanghai',
      const Duration(hours: 9): 'Asia/Tokyo',
      const Duration(hours: -5): 'America/New_York',
      const Duration(hours: -8): 'America/Los_Angeles',
    };

    final tzName = offsetMap[offset];
    if (tzName != null) {
      try {
        tz.setLocalLocation(tz.getLocation(tzName));
        debugPrint('NotificationService: Fallback timezone set to $tzName');
        return;
      } catch (_) {}
    }
    debugPrint('NotificationService: Using UTC offset fallback');
  }

  /// Request notification permission (Android 13+)
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android == null) {
      debugPrint('NotificationService: Not on Android');
      return false;
    }

    // Request notification permission
    final granted = await android.requestNotificationsPermission() ?? false;
    debugPrint('NotificationService: Notification permission: $granted');

    // Check exact alarm capability
    final canScheduleExact =
        await android.canScheduleExactNotifications() ?? false;
    debugPrint(
      'NotificationService: Exact alarm permission: $canScheduleExact',
    );

    if (!canScheduleExact) {
      debugPrint('NotificationService: Requesting exact alarm permission...');
      await android.requestExactAlarmsPermission();
    }

    return granted;
  }

  /// Request to ignore battery optimizations (important for background notifications)
  Future<void> requestIgnoreBatteryOptimizations() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      // Note: This requires permission_handler or a custom intent
      // We'll use a message to the user for now as permission_handler is already in the project
    }
  }

  /// Check if notification permission is granted
  Future<bool> hasPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return false;
    return await android.areNotificationsEnabled() ?? false;
  }

  /// Show an immediate notification
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      debugPrint(
        'NotificationService: Not initialized, cannot show notification',
      );
      return;
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'hydroman_reminders',
        'Water Reminders',
        channelDescription: 'Hydration reminder notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        playSound: true,
        enableVibration: true,
        styleInformation: const BigTextStyleInformation(''),
      ),
    );

    try {
      await _plugin.show(id, title, body, details);
      debugPrint('NotificationService: Showed notification id=$id');
    } catch (e) {
      debugPrint('NotificationService: Failed to show notification: $e');
    }
  }

  /// Schedule a daily repeating notification at the given local time
  Future<bool> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (!_initialized) {
      debugPrint('NotificationService: Not initialized, cannot schedule');
      return false;
    }

    try {
      // Use local DateTime for correct time calculation
      // This avoids issues with tz.local potentially being wrong
      final now = DateTime.now();
      var scheduledLocal = DateTime(now.year, now.month, now.day, hour, minute);

      // If the time has already passed today, schedule for tomorrow
      if (scheduledLocal.isBefore(now)) {
        scheduledLocal = scheduledLocal.add(const Duration(days: 1));
      }

      // Convert local DateTime to TZDateTime
      // tz.TZDateTime.from() correctly converts using millisecondsSinceEpoch
      // so it works correctly regardless of tz.local setting
      final scheduled = tz.TZDateTime.from(scheduledLocal, tz.local);

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'hydroman_reminders',
          'Water Reminders',
          channelDescription: 'Hydration reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          playSound: true,
          enableVibration: true,
        ),
      );

      // Try exact scheduling first, fall back to inexact
      AndroidScheduleMode scheduleMode =
          AndroidScheduleMode.exactAllowWhileIdle;

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final canExact = await android.canScheduleExactNotifications() ?? false;
        if (!canExact) {
          scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
          debugPrint(
            'NotificationService: Using inexact scheduling (no exact alarm permission)',
          );
        }
      }

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint(
        'NotificationService: Scheduled reminder id=$id at '
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} '
        '(TZ: ${scheduled.timeZoneName}, scheduled: $scheduled)',
      );
      return true;
    } catch (e) {
      debugPrint('NotificationService: Failed to schedule reminder id=$id: $e');
      return false;
    }
  }

  /// Schedule all enabled reminders from the list
  Future<int> scheduleAllReminders(List<Reminder> reminders) async {
    if (!_initialized) {
      debugPrint('NotificationService: Not initialized, attempting init...');
      await initialize();
    }

    // Cancel all existing
    await cancelAll();

    // Check permission first, request if not granted
    var hasNotifPermission = await hasPermission();
    debugPrint('NotificationService: hasPermission=$hasNotifPermission');
    if (!hasNotifPermission) {
      debugPrint('NotificationService: No permission, requesting...');
      hasNotifPermission = await requestPermission();
      if (!hasNotifPermission) {
        debugPrint(
          'NotificationService: Permission denied after request, skipping',
        );
        return 0;
      }
    }

    int scheduled = 0;
    for (int i = 0; i < reminders.length; i++) {
      final r = reminders[i];
      if (!r.isEnabled) continue;

      final parts = r.time.split(':');
      if (parts.length != 2) continue;

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      final success = await scheduleDailyReminder(
        id: int.tryParse(r.id) ?? r.id.hashCode,
        title: 'Time to Hydrate!',
        body: r.label.isNotEmpty
            ? r.label
            : 'Drink some water to stay healthy!',
        hour: hour,
        minute: minute,
      );

      if (success) scheduled++;
    }

    debugPrint(
      'NotificationService: Scheduled $scheduled/${reminders.where((r) => r.isEnabled).length} reminders',
    );
    return scheduled;
  }

  /// Cancel a specific notification
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('NotificationService: Cancelled all notifications');
  }

  /// Get list of pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPending() async {
    return await _plugin.pendingNotificationRequests();
  }

  /// Handle notification tap
  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('NotificationService: Notification tapped: ${response.payload}');
  }

  /// Show a test notification to verify sound and vibration
  Future<void> testNotification() async {
    await showNow(
      id: 999,
      title: 'Test Notification',
      body: 'Water reminder sound and vibration test.',
    );
  }

  /// Schedule a test notification using zonedSchedule (AlarmManager).
  /// Works even after app is closed.
  Future<String> testScheduledNotification2s() async {
    if (!_initialized) {
      return 'Error: NotificationService not initialized';
    }

    try {
      // Schedule via AlarmManager for 10 seconds (survives app close)
      final testTime = DateTime.now().add(const Duration(seconds: 10));
      final scheduled = tz.TZDateTime.from(testTime, tz.local);

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final canExact = await android?.canScheduleExactNotifications() ?? false;
      final scheduleMode = canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'hydroman_reminders',
          'Water Reminders',
          channelDescription: 'Hydration reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          playSound: true,
          enableVibration: true,
        ),
      );

      await _plugin.zonedSchedule(
        998,
        '💧 Scheduled Test',
        'This was scheduled 10s ago. Background notifications work!',
        scheduled,
        details,
        androidScheduleMode: scheduleMode,
      );

      final pending = await getPending();
      return 'Notification scheduled for 10s from now.\n'
          'Mode: ${canExact ? "exact" : "inexact"}\n'
          'TZ: ${tz.local.name}\n'
          'Pending: ${pending.length}\n\n'
          'You can close the app — it should still fire!';
    } catch (e) {
      return 'Schedule failed: $e';
    }
  }

  /// Schedule a test notification 5 seconds from now
  Future<String> testScheduledNotification() async {
    if (!_initialized) {
      return 'Error: NotificationService not initialized';
    }
    try {
      final testTime = DateTime.now().add(const Duration(seconds: 5));
      final scheduled = tz.TZDateTime.from(testTime, tz.local);

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final canExact = await android?.canScheduleExactNotifications() ?? false;
      final scheduleMode = canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'hydroman_reminders',
          'Water Reminders',
          channelDescription: 'Hydration reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          playSound: true,
          enableVibration: true,
        ),
      );

      await _plugin.zonedSchedule(
        997,
        '💧 Scheduled Test (5s)',
        'This was scheduled 5s ago. Scheduling works!',
        scheduled,
        details,
        androidScheduleMode: scheduleMode,
      );

      return 'Notification will fire in 5 seconds';
    } catch (e) {
      return 'Schedule failed: $e';
    }
  }

  /// Get debug info about current notification state
  Future<String> getDebugInfo() async {
    final hasNotif = await hasPermission();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final canExact = await android?.canScheduleExactNotifications() ?? false;
    final pending = await getPending();

    return 'Permission: $hasNotif\n'
        'Exact alarm: $canExact\n'
        'Timezone: ${tz.local.name}\n'
        'Pending: ${pending.length}\n'
        'Initialized: $_initialized';
  }
}

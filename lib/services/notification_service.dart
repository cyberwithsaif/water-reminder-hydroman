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
      // Create or update notification channel (Android handles duplicates gracefully)
      final channel = AndroidNotificationChannel(
        'hydroman_reminders_v3',
        'Water Reminders',
        description: 'Hydration reminder notifications',
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('water_reminder'),
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
        'hydroman_reminders_v3',
        'Water Reminders',
        channelDescription: 'Hydration reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('water_reminder'),
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
      // Use TZDateTime directly for the "now" check and scheduling
      // This is the most robust way to handle daily repeats accurately
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If the time has already passed today, schedule for tomorrow
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'hydroman_reminders_v3',
          'Water Reminders',
          channelDescription: 'Hydration reminder notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('water_reminder'),
          enableVibration: true,
          subText: 'Daily Reminder',
          showWhen: true,
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
        '(Target Local Time: $scheduled, TZ: ${tz.local.name})',
      );
      return true;
    } catch (e) {
      debugPrint('NotificationService: Failed to schedule reminder id=$id: $e');
      return false;
    }
  }

  /// Generate a safe 32-bit notification ID from a reminder ID string.
  /// Android notification IDs must fit in a 32-bit signed int.
  int _safeNotificationId(String reminderId, int fallbackIndex) {
    final parsed = int.tryParse(reminderId);
    if (parsed != null && parsed < 100000) {
      // Small IDs (default reminders "1"-"5") are safe to use directly
      return parsed + 1000;
    }
    // For large IDs (millisecond timestamps), use hashCode bounded to safe range
    return (reminderId.hashCode.abs() % 2000000000) + 1000;
  }

  /// Check if a reminder time falls within the night mute window.
  /// repeatDays is a 7-element list [Mon, Tue, Wed, Thu, Fri, Sat, Sun].
  bool _isDuringNightMute({
    required int hour,
    required int minute,
    required bool nightMuteEnabled,
    required String bedtime,
    required String wakeTime,
    required List<bool> repeatDays,
  }) {
    if (!nightMuteEnabled) return false;

    final bedParts = bedtime.split(':');
    final wakeParts = wakeTime.split(':');
    if (bedParts.length != 2 || wakeParts.length != 2) return false;

    final bedHour = int.tryParse(bedParts[0]) ?? 22;
    final bedMinute = int.tryParse(bedParts[1]) ?? 0;
    final wakeHour = int.tryParse(wakeParts[0]) ?? 7;
    final wakeMinute = int.tryParse(wakeParts[1]) ?? 0;

    final reminderMinutes = hour * 60 + minute;
    final bedMinutes = bedHour * 60 + bedMinute;
    final wakeMinutes = wakeHour * 60 + wakeMinute;

    // Check if any repeat day is enabled (if none are, don't mute)
    final anyDayEnabled = repeatDays.any((d) => d);
    if (!anyDayEnabled) return false;

    // Check if today is a mute day
    // DateTime.now().weekday: 1=Mon, 2=Tue, ..., 7=Sun
    // repeatDays index: 0=Mon, 1=Tue, ..., 6=Sun
    final todayIndex = DateTime.now().weekday - 1; // Convert to 0-based
    if (repeatDays.length > todayIndex && !repeatDays[todayIndex]) {
      return false; // Night mute not active today
    }

    if (bedMinutes <= wakeMinutes) {
      // Same-day mute window (e.g., 01:00 - 06:00)
      return reminderMinutes >= bedMinutes && reminderMinutes < wakeMinutes;
    } else {
      // Overnight mute window (e.g., 22:00 - 07:00)
      return reminderMinutes >= bedMinutes || reminderMinutes < wakeMinutes;
    }
  }

  /// Schedule all enabled reminders from the list.
  /// Pass night mute settings to skip reminders during sleep hours.
  Future<int> scheduleAllReminders(
    List<Reminder> reminders, {
    bool nightMuteEnabled = false,
    String nightMuteBedtime = '22:00',
    String nightMuteWakeTime = '07:00',
    List<bool> nightMuteRepeatDays = const [
      true,
      true,
      true,
      true,
      true,
      false,
      false,
    ],
  }) async {
    if (!_initialized) {
      debugPrint('NotificationService: Not initialized, attempting init...');
      await initialize();
    }

    // Check permission BEFORE cancelling existing notifications.
    // If permission is denied, keep existing scheduled notifications intact.
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

    // Cancel all existing (only after confirming we have permission to reschedule)
    await cancelAll();

    int scheduled = 0;
    int skippedNightMute = 0;
    for (int i = 0; i < reminders.length; i++) {
      final r = reminders[i];
      if (!r.isEnabled) continue;

      final parts = r.time.split(':');
      if (parts.length != 2) continue;

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      // Skip reminders during night mute window
      if (_isDuringNightMute(
        hour: hour,
        minute: minute,
        nightMuteEnabled: nightMuteEnabled,
        bedtime: nightMuteBedtime,
        wakeTime: nightMuteWakeTime,
        repeatDays: nightMuteRepeatDays,
      )) {
        skippedNightMute++;
        debugPrint(
          'NotificationService: Skipping reminder ${r.time} (night mute)',
        );
        continue;
      }

      final success = await scheduleDailyReminder(
        id: _safeNotificationId(r.id, i),
        title: 'Time to Hydrate!',
        body: r.label.isNotEmpty
            ? r.label
            : 'Drink some water to stay healthy!',
        hour: hour,
        minute: minute,
      );

      if (success) {
        scheduled++;
      } else {
        debugPrint(
          'NotificationService: FAILED to schedule reminder $i (${r.time})',
        );
      }
    }

    debugPrint(
      'NotificationService: Scheduled $scheduled/${reminders.where((r) => r.isEnabled).length} reminders'
      '${skippedNightMute > 0 ? ' ($skippedNightMute skipped by night mute)' : ''}',
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
          'hydroman_reminders_v3',
          'Water Reminders',
          channelDescription: 'Hydration reminder notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('water_reminder'),
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
          'hydroman_reminders_v3',
          'Water Reminders',
          channelDescription: 'Hydration reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('water_reminder'),
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

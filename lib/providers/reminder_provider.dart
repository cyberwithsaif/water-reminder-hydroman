import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/reminder.dart';
import '../data/repositories/reminder_repository.dart';
import '../services/notification_service.dart';
import 'user_provider.dart';
import 'auth_provider.dart';

// Repository provider
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository();
});

// All reminders
final remindersProvider =
    StateNotifierProvider<RemindersNotifier, List<Reminder>>((ref) {
      final repo = ref.watch(reminderRepositoryProvider);
      return RemindersNotifier(repo, ref);
    });

// Night mute settings
final nightMuteEnabledProvider = StateProvider<bool>((ref) => true);
final nightMuteBedtimeProvider = StateProvider<String>((ref) => '22:00');
final nightMuteWakeTimeProvider = StateProvider<String>((ref) => '07:00');
final nightMuteRepeatDaysProvider = StateProvider<List<bool>>(
  (ref) => [true, true, true, true, true, false, false],
);

// Next scheduled reminder (only considers enabled reminders)
final nextReminderProvider = Provider<Reminder?>((ref) {
  final reminders = ref.watch(remindersProvider);
  final enabled = reminders.where((r) => r.isEnabled).toList();
  if (enabled.isEmpty) return null;

  final now = DateTime.now();
  final currentMinutes = now.hour * 60 + now.minute;

  Reminder? next;
  int minDiff = 24 * 60 + 1;

  for (final r in enabled) {
    final parts = r.time.split(':');
    if (parts.length != 2) continue;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final reminderMinutes = h * 60 + m;

    int diff = reminderMinutes - currentMinutes;
    if (diff <= 0) diff += 24 * 60; // Next occurrence is tomorrow

    if (diff < minDiff) {
      minDiff = diff;
      next = r;
    }
  }

  return next;
});

class RemindersNotifier extends StateNotifier<List<Reminder>> {
  final ReminderRepository _repo;
  final Ref _ref;

  RemindersNotifier(this._repo, this._ref) : super([]);

  /// Load reminder data from Hive only (fast, no notification scheduling)
  Future<void> loadDataOnly() async {
    await _repo.createDefaultReminders();
    state = _repo.getAll();
  }

  /// Schedule notifications for loaded reminders (requires NotificationService)
  Future<void> scheduleNotifications() async {
    if (state.isEmpty) {
      loadDataOnly(); // Ensure data is loaded
    }
    await _reschedule();
  }

  Future<void> load() async {
    await _repo.createDefaultReminders();
    state = _repo.getAll();
    await _reschedule();
  }

  Future<void> addReminder(Reminder reminder) async {
    await _repo.addReminder(reminder);
    state = [..._repo.getAll()];
    await _reschedule();
    // Proactive sync push
    _ref.read(syncServiceProvider).syncAll();
  }

  Future<void> deleteReminder(String id) async {
    await _repo.deleteReminder(id);
    state = [..._repo.getAll()];
    await _reschedule();
    // Proactive sync push
    _ref.read(syncServiceProvider).syncAll();
  }

  Future<void> toggleReminder(String id) async {
    await _repo.toggleReminder(id);
    // Explicitly create a new list reference to trigger Riverpod watchers
    state = [..._repo.getAll()];
    await _reschedule();
  }

  Future<void> _reschedule() async {
    try {
      final profile = _ref.read(userProfileProvider);
      debugPrint(
        'RemindersNotifier: profile=${profile != null}, '
        'notificationsEnabled=${profile?.notificationsEnabled}',
      );

      // Only cancel if user explicitly disabled notifications
      if (profile != null && !profile.notificationsEnabled) {
        await NotificationService.instance.cancelAll();
        debugPrint(
          'RemindersNotifier: Notifications disabled by user, cancelled all',
        );
        return;
      }

      // If profile is null, still try to schedule (don't block on missing profile)
      final enabledReminders = state.where((r) => r.isEnabled).toList();
      debugPrint(
        'RemindersNotifier: ${enabledReminders.length} enabled reminders to schedule',
      );

      if (enabledReminders.isEmpty) {
        await NotificationService.instance.cancelAll();
        return;
      }

      final count = await NotificationService.instance.scheduleAllReminders(
        state,
      );

      // Verify scheduled count
      final pending = await NotificationService.instance.getPending();
      debugPrint(
        'RemindersNotifier: Scheduled=$count, Pending=${pending.length}',
      );

      if (count == 0 && enabledReminders.isNotEmpty) {
        debugPrint(
          'RemindersNotifier: WARNING - 0 scheduled despite ${enabledReminders.length} enabled!',
        );
      }
    } catch (e) {
      debugPrint('RemindersNotifier: Reschedule failed: $e');
    }
  }
}

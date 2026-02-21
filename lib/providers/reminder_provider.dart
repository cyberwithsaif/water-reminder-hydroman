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

// Night mute settings (Now persistent via UserProfile)
// These are kept as lightweight proxies to the UserProfile for easier transition
// but they really should be accessed via userProfileProvider directly.
final nightMuteEnabledProvider = Provider<bool>((ref) {
  return ref.watch(userProfileProvider)?.nightMuteEnabled ?? true;
});

final nightMuteBedtimeProvider = Provider<String>((ref) {
  return ref.watch(userProfileProvider)?.nightMuteBedtime ?? '22:00';
});

final nightMuteWakeTimeProvider = Provider<String>((ref) {
  return ref.watch(userProfileProvider)?.nightMuteWakeTime ?? '07:00';
});

final nightMuteRepeatDaysProvider = Provider<List<bool>>((ref) {
  return ref.watch(userProfileProvider)?.nightMuteRepeatDays ??
      const [true, true, true, true, true, false, false];
});

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
      await loadDataOnly(); // Ensure data is loaded before scheduling
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
    // Proactive sync push with state refresh callback
    _ref
        .read(syncServiceProvider)
        .syncAll(
          onComplete: () {
            state = [..._repo.getAll()];
          },
        );
  }

  Future<void> deleteReminders(List<String> ids) async {
    if (ids.isEmpty) return;

    // Hard-delete locally (permanent, not soft-delete)
    await _repo.hardDeleteReminders(ids);
    state = [..._repo.getAll()];
    await _reschedule();

    // Delete from server immediately
    try {
      final api = _ref.read(apiServiceProvider);
      if (api.token != null) {
        // We do sequential deletes for now as the API might not support bulk delete
        for (final id in ids) {
          await api.deleteReminder(id).catchError((e) {
            debugPrint('RemindersNotifier: Server delete failed for $id: $e');
          });
        }
      }
    } catch (e) {
      debugPrint('RemindersNotifier: Bulk server delete failed: $e');
    }

    // Trigger proactive sync
    _ref
        .read(syncServiceProvider)
        .syncAll(
          onComplete: () {
            state = [..._repo.getAll()];
          },
        );
  }

  Future<void> deleteReminder(String id) async {
    await deleteReminders([id]);
  }

  Future<void> toggleReminder(String id) async {
    await _repo.toggleReminder(id);
    // Explicitly create a new list reference to trigger Riverpod watchers
    state = [..._repo.getAll()];
    await _reschedule();

    // Trigger proactive sync
    _ref
        .read(syncServiceProvider)
        .syncAll(
          onComplete: () {
            state = [..._repo.getAll()];
          },
        );
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

      // Read night mute settings from user profile
      final nightMuteEnabled = profile?.nightMuteEnabled ?? false;
      final nightMuteBedtime = profile?.nightMuteBedtime ?? '22:00';
      final nightMuteWakeTime = profile?.nightMuteWakeTime ?? '07:00';
      final nightMuteRepeatDays =
          profile?.nightMuteRepeatDays ??
          const [true, true, true, true, true, false, false];

      final count = await NotificationService.instance.scheduleAllReminders(
        state,
        nightMuteEnabled: nightMuteEnabled,
        nightMuteBedtime: nightMuteBedtime,
        nightMuteWakeTime: nightMuteWakeTime,
        nightMuteRepeatDays: nightMuteRepeatDays,
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

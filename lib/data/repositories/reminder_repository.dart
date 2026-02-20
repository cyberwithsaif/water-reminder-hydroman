import 'package:hive/hive.dart';
import '../models/reminder.dart';
import '../../core/constants/app_constants.dart';

class ReminderRepository {
  late Box<Reminder> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Reminder>(AppConstants.reminderBox);
  }

  List<Reminder> getAll() {
    return _box.values
        .whereType<Reminder>() // Filter out metadata keys
        .where((r) => r.deletedAt == null)
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  Future<void> addReminder(Reminder reminder) async {
    await _box.put(reminder.id, reminder);
  }

  Future<void> deleteReminder(String id) async {
    final reminder = _box.get(id);
    if (reminder != null) {
      reminder.deletedAt = DateTime.now();
      await reminder.save();

      // Add to deletion blocklist
      final deletedBox = await Hive.openBox<bool>(
        AppConstants.deletedReminderBox,
      );
      await deletedBox.put(id, true);
    }
  }

  /// Permanently delete items that have been marked as deleted
  Future<void> hardDeleteReminder(String id) async {
    await _box.delete(id);

    // Also remove from blocklist if it was there (to keep it clean)
    final deletedBox = await Hive.openBox<bool>(
      AppConstants.deletedReminderBox,
    );
    await deletedBox.delete(id);
  }

  /// Permanently delete items that have been synced as deletions
  Future<void> purgeDeletedReminders() async {
    final toDelete = _box.values
        .where((r) => r.deletedAt != null)
        .map((r) => r.id)
        .toList();
    for (final id in toDelete) {
      await _box.delete(id);
    }
  }

  Future<void> toggleReminder(String id) async {
    final reminder = _box.get(id);
    if (reminder != null) {
      reminder.isEnabled = !reminder.isEnabled;
      await reminder.save();
    }
  }

  List<Reminder> getEnabled() {
    return _box.values.where((r) => r.deletedAt == null && r.isEnabled).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  Future<void> createDefaultReminders() async {
    final settings = await Hive.openBox(AppConstants.settingsBox);
    final flag = settings.get('defaults_created_v2');
    if (flag != null) return;
    if (_box.values.whereType<Reminder>().isNotEmpty) return;

    final defaults = [
      Reminder(
        id: '1',
        time: '08:00',
        label: 'Wake up water',
        icon: 'wb_twilight',
      ),
      Reminder(
        id: '2',
        time: '11:00',
        label: 'Mid-morning sip',
        icon: 'water_bottle',
      ),
      Reminder(
        id: '3',
        time: '14:00',
        label: 'Lunch hydration',
        icon: 'lunch_dining',
      ),
      Reminder(
        id: '4',
        time: '17:00',
        label: 'Afternoon refill',
        icon: 'local_cafe',
      ),
      Reminder(id: '5', time: '21:00', label: 'Evening glass', icon: 'bedtime'),
    ];

    for (final r in defaults) {
      await _box.put(r.id, r);
    }
    await settings.put('defaults_created_v2', true);
  }
}

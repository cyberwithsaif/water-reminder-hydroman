import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'api_service.dart';
import '../data/models/water_log.dart';
import '../data/models/reminder.dart';
import '../data/models/user_profile.dart';
import '../core/constants/app_constants.dart';

class SyncService {
  final ApiService _api;
  static const String _syncBoxName = 'sync_meta';

  SyncService(this._api);

  /// Run full bidirectional sync
  /// [onComplete] is called after sync finishes so providers can reload
  Future<void> syncAll({VoidCallback? onComplete}) async {
    if (_api.token == null) return;

    try {
      final isOnline = await _api.healthCheck();
      if (!isOnline) {
        debugPrint('SyncService: Server unreachable, skipping sync');
        return;
      }

      await _syncWaterLogs();
      await _syncReminders();
      await _syncProfile();

      // Update last sync timestamp
      final syncBox = await Hive.openBox(_syncBoxName);
      await syncBox.put('lastSync', DateTime.now().toIso8601String());

      debugPrint('SyncService: Sync complete');

      // Notify caller so providers can reload with synced data
      onComplete?.call();
    } catch (e) {
      debugPrint('SyncService: Sync failed — $e');
    }
  }

  /// Push local water logs to server, then pull remote updates
  Future<void> _syncWaterLogs() async {
    final logBox = await Hive.openBox<WaterLog>(AppConstants.waterLogBox);
    final syncBox = await Hive.openBox(_syncBoxName);
    final lastSync = syncBox.get('lastWaterLogSync') as String?;

    // Push local logs
    final localLogs = logBox.values.toList();
    if (localLogs.isNotEmpty) {
      final logsData = localLogs
          .map(
            (log) => <String, dynamic>{
              'id': log.id,
              'amount_ml': log.amountMl,
              'cup_type': log.cupType,
              'timestamp': log.timestamp.toIso8601String(),
              if (log.deletedAt != null) 'deleted': true,
            },
          )
          .toList();
      await _api.syncWaterLogs(logsData);

      // Purge local soft-deletes after successful sync
      final toPurge = localLogs.where((log) => log.deletedAt != null);
      for (final log in toPurge) {
        await logBox.delete(log.id);
      }
    }

    // Pull remote logs (all if first sync, or since last sync)
    final remoteLogs = await _api.getWaterLogs(since: lastSync);
    int pulled = 0;
    for (final remote in remoteLogs) {
      final remoteMap = remote as Map<String, dynamic>;

      if (remoteMap['deleted'] == true) {
        // Soft-deleted on server → remove locally
        await logBox.delete(remoteMap['id']);
        continue;
      }

      // Upsert: if not present locally, add it
      final existing = logBox.get(remoteMap['id']);
      if (existing == null) {
        await logBox.put(
          remoteMap['id'],
          WaterLog(
            id: remoteMap['id'],
            amountMl: remoteMap['amount_ml'],
            cupType: remoteMap['cup_type'] ?? 'glass',
            timestamp: DateTime.parse(remoteMap['timestamp']),
          ),
        );
        pulled++;
      }
    }
    debugPrint(
      'SyncService: Water logs — pushed ${localLogs.length}, pulled $pulled',
    );

    await syncBox.put('lastWaterLogSync', DateTime.now().toIso8601String());
  }

  /// Push local reminders to server, then pull remote
  Future<void> _syncReminders() async {
    final remBox = await Hive.openBox<Reminder>(AppConstants.reminderBox);
    final syncBox = await Hive.openBox(_syncBoxName);

    // Push
    final localReminders = remBox.values.toList();
    if (localReminders.isNotEmpty) {
      final data = localReminders
          .map(
            (r) => <String, dynamic>{
              'id': r.id,
              'time': r.time,
              'label': r.label,
              'is_enabled': r.isEnabled,
              'icon': r.icon,
              if (r.deletedAt != null) 'deleted': true,
            },
          )
          .toList();
      await _api.syncReminders(data);

      // Purge local soft-deletes after successful sync
      final toPurge = localReminders.where((r) => r.deletedAt != null);
      for (final r in toPurge) {
        // Hard-delete on server and then locally
        await _api.deleteReminder(r.id);
        await remBox.delete(r.id);
      }
    }

    // Pull
    final remoteReminders = await _api.getReminders();
    final deletedBox = await Hive.openBox<bool>(
      AppConstants.deletedReminderBox,
    );
    int pulled = 0;
    int skipped = 0;
    for (final remote in remoteReminders) {
      final remoteMap = remote as Map<String, dynamic>;
      final id = remoteMap['id'];

      // Check blocklist first (most important)
      if (deletedBox.get(id) == true) {
        debugPrint(
          'SyncService: Skipping ID $id because it is in DELETION BLOCKLIST',
        );
        // Still exists on server but we deleted it locally
        await _api.deleteReminder(id);
        skipped++;
        continue;
      }

      if (remoteMap['deleted'] == true) {
        debugPrint(
          'SyncService: Removing ID $id because server says it is DELETED',
        );
        // Deleted on server → HARD remove locally
        await remBox.delete(id);
        // Also remove from blocklist to keep it clean (server confirmed delete)
        await deletedBox.delete(id);
        continue;
      }

      final existing = remBox.get(id);
      if (existing != null) {
        // Update existing if needed, but for now just skip to avoid duplicates
        // Note: We could check if fields changed here
        continue;
      }

      // FINAL DEFENSE: Check if we JUST deleted it in this sync cycle or previously
      if (deletedBox.get(id) == true) {
        debugPrint('SyncService: Final defense triggered for ID $id');
        continue;
      }

      debugPrint('SyncService: Pulling new reminder ID $id');
      await remBox.put(
        id,
        Reminder(
          id: id,
          time: remoteMap['time'],
          label: remoteMap['label'] ?? '',
          isEnabled: remoteMap['is_enabled'] ?? true,
          icon: remoteMap['icon'] ?? 'water_drop',
        ),
      );
      pulled++;
    }
    debugPrint(
      'SyncService: Reminders — pushed ${localReminders.length}, pulled $pulled, skipped $skipped',
    );

    await syncBox.put('lastReminderSync', DateTime.now().toIso8601String());
  }

  /// Bidirectional profile sync: push local → server, pull server → local
  Future<void> _syncProfile() async {
    try {
      final profileBox = await Hive.openBox<UserProfile>(
        AppConstants.userProfileBox,
      );
      final localProfile = profileBox.get('profile');

      if (localProfile != null && localProfile.isOnboarded) {
        // Local profile exists → push to server
        await _api.updateProfile({
          'name': localProfile.name,
          'gender': localProfile.gender,
          'weight_kg': localProfile.weightKg,
          'daily_goal_ml': localProfile.dailyGoalMl,
          'wake_time': localProfile.wakeTime,
          'sleep_time': localProfile.sleepTime,
          'weight_unit': localProfile.weightUnit,
          'default_cup_ml': localProfile.defaultCupMl,
        });
        debugPrint('SyncService: Profile pushed to server');
      } else {
        // No local profile (reinstall) → pull from server
        try {
          final serverProfile = await _api.getProfile();
          if (serverProfile.isNotEmpty && serverProfile['name'] != null) {
            final profile = UserProfile(
              name: serverProfile['name'] ?? '',
              gender: serverProfile['gender'] ?? 'male',
              weightKg:
                  (serverProfile['weight_kg'] as num?)?.toDouble() ?? 70.0,
              dailyGoalMl: serverProfile['daily_goal_ml'] as int? ?? 2500,
              wakeTime: serverProfile['wake_time'] ?? '07:00',
              sleepTime: serverProfile['sleep_time'] ?? '23:00',
              weightUnit: serverProfile['weight_unit'] ?? 'kg',
              defaultCupMl: serverProfile['default_cup_ml'] as int? ?? 250,
              isOnboarded: true,
              notificationsEnabled: true,
            );
            await profileBox.put('profile', profile);
            debugPrint('SyncService: Profile pulled from server');
          }
        } catch (e) {
          debugPrint('SyncService: Profile pull failed — $e');
        }
      }
    } catch (e) {
      debugPrint('SyncService: Profile sync error — $e');
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/user_repository.dart';

// Repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// User profile state
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>((ref) {
      final repo = ref.watch(userRepositoryProvider);
      return UserProfileNotifier(repo);
    });

// Is onboarded
final isOnboardedProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile?.isOnboarded ?? false;
});

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  final UserRepository _repo;

  UserProfileNotifier(this._repo) : super(null);

  void load() {
    // Set null first to force Riverpod state change notification,
    // since Hive returns the same object reference
    state = null;
    final profile = _repo.getProfile();

    // AUTO-FIX: If profile exists and has a name but isn't marked as onboarded,
    // it's an old user. Mark them onboarded so they don't see onboarding again.
    if (profile != null && !profile.isOnboarded && profile.name.isNotEmpty) {
      debugPrint('UserProfileNotifier: Migrating legacy profile to onboarded');
      profile.isOnboarded = true;
      profile.save();
    }

    state = profile;
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _repo.saveProfile(profile);
    state = null;
    state = profile;
  }

  Future<void> updateGoal(int goalMl) async {
    if (state != null) {
      state!.dailyGoalMl = goalMl;
      await state!.save();
      state = null;
      state = _repo.getProfile();
    }
  }

  Future<void> updateWeight(double weightKg) async {
    if (state != null) {
      state!.weightKg = weightKg;
      await state!.save();
      state = null;
      state = _repo.getProfile();
    }
  }

  Future<void> updateName(String name) async {
    if (state != null) {
      state!.name = name;
      await state!.save();
      state = null;
      state = _repo.getProfile();
    }
  }

  Future<void> toggleNotifications(bool enabled) async {
    if (state != null) {
      state!.notificationsEnabled = enabled;
      await state!.save();
      state = null;
      state = _repo.getProfile();
    }
  }

  Future<void> updateNightMute({
    bool? isEnabled,
    String? bedtime,
    String? wakeTime,
    List<bool>? repeatDays,
  }) async {
    if (state != null) {
      if (isEnabled != null) state!.nightMuteEnabled = isEnabled;
      if (bedtime != null) state!.nightMuteBedtime = bedtime;
      if (wakeTime != null) state!.nightMuteWakeTime = wakeTime;
      if (repeatDays != null) state!.nightMuteRepeatDays = repeatDays;
      await state!.save();
      state = null;
      state = _repo.getProfile();
    }
  }
}

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
    state = _repo.getProfile();
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
}

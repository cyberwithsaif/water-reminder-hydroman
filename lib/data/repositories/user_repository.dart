import 'package:hive/hive.dart';
import '../models/user_profile.dart';
import '../../core/constants/app_constants.dart';

class UserRepository {
  Box<UserProfile> get _box =>
      Hive.box<UserProfile>(AppConstants.userProfileBox);

  Future<void> init() async {
    if (!Hive.isBoxOpen(AppConstants.userProfileBox)) {
      await Hive.openBox<UserProfile>(AppConstants.userProfileBox);
    }
  }

  UserProfile? getProfile() {
    if (!Hive.isBoxOpen(AppConstants.userProfileBox)) return null;
    return _box.get('profile');
  }

  Future<void> saveProfile(UserProfile profile) async {
    await init();
    await _box.put('profile', profile);
  }

  bool get isOnboarded {
    final profile = getProfile();
    return profile?.isOnboarded ?? false;
  }

  Future<void> updateGoal(int goalMl) async {
    await init();
    final profile = getProfile();
    if (profile != null) {
      profile.dailyGoalMl = goalMl;
      await profile.save();
    }
  }
}

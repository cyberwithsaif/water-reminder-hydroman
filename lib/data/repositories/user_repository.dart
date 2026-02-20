import 'package:hive/hive.dart';
import '../models/user_profile.dart';
import '../../core/constants/app_constants.dart';

class UserRepository {
  late Box<UserProfile> _box;

  Future<void> init() async {
    _box = await Hive.openBox<UserProfile>(AppConstants.userProfileBox);
  }

  UserProfile? getProfile() {
    return _box.get('profile');
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _box.put('profile', profile);
  }

  bool get isOnboarded {
    final profile = getProfile();
    return profile?.isOnboarded ?? false;
  }

  Future<void> updateGoal(int goalMl) async {
    final profile = getProfile();
    if (profile != null) {
      profile.dailyGoalMl = goalMl;
      await profile.save();
    }
  }
}

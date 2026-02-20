import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  String gender; // 'male', 'female', 'other'

  @HiveField(1)
  double weightKg;

  @HiveField(2)
  int dailyGoalMl;

  @HiveField(3)
  String wakeTime; // HH:mm format

  @HiveField(4)
  String sleepTime; // HH:mm format

  @HiveField(5)
  bool isOnboarded;

  @HiveField(6)
  String name;

  @HiveField(7)
  String weightUnit; // 'kg' or 'lbs'

  @HiveField(8)
  bool notificationsEnabled; // Notification toggle state

  UserProfile({
    this.gender = 'male',
    this.weightKg = 70.0,
    this.dailyGoalMl = 2500,
    this.wakeTime = '07:00',
    this.sleepTime = '23:00',
    this.isOnboarded = false,
    this.name = '',
    this.weightUnit = 'kg',
    this.notificationsEnabled = true,
  });

  double get weightDisplay =>
      weightUnit == 'lbs' ? weightKg * 2.20462 : weightKg;
}

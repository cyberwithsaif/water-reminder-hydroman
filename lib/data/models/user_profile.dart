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
  bool notificationsEnabled;

  @HiveField(9)
  bool nightMuteEnabled;

  @HiveField(10)
  String nightMuteBedtime;

  @HiveField(11)
  String nightMuteWakeTime;

  @HiveField(12)
  List<bool> nightMuteRepeatDays;

  @HiveField(13, defaultValue: 250)
  int defaultCupMl;

  @HiveField(14, defaultValue: 0)
  int hydroCoins;

  @HiveField(15, defaultValue: 'blue')
  String themeName; // 'blue', 'orange', 'green'

  @HiveField(16)
  DateTime? lastCoinClaimDate;

  @HiveField(17, defaultValue: false)
  bool isPrivacyAccepted;

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
    this.nightMuteEnabled = true,
    this.nightMuteBedtime = '22:00',
    this.nightMuteWakeTime = '07:00',
    this.nightMuteRepeatDays = const [
      true,
      true,
      true,
      true,
      true,
      false,
      false,
    ],
    this.defaultCupMl = 250,
    this.hydroCoins = 0,
    this.themeName = 'blue',
    this.isPrivacyAccepted = false,
    this.lastCoinClaimDate,
  });

  double get weightDisplay =>
      weightUnit == 'lbs' ? weightKg * 2.20462 : weightKg;
}

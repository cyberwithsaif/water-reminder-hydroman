class AppConstants {
  AppConstants._();

  // Goal limits
  static const int minGoalMl = 500;
  static const int maxGoalMl = 4000;
  static const int defaultGoalMl = 2500;
  static const int goalStepMl = 50;

  // Cup sizes
  static const int espressoMl = 100;
  static const int glassMl = 250;
  static const int bottleMl = 500;
  static const int sportsMl = 750;

  // Default quick-add amounts
  static const int quickAdd1 = 250;
  static const int quickAdd2 = 500;

  // Reminder defaults
  static const int defaultReminderIntervalMinutes = 60;
  static const int snoozeMinutes = 15;

  // Hive box names
  static const String userProfileBox = 'user_profile';
  static const String waterLogBox = 'water_logs';
  static const String reminderBox = 'reminders';
  static const String deletedReminderBox = 'deleted_reminders';
  static const String settingsBox = 'settings';

  // Hive type IDs
  static const int userProfileTypeId = 0;
  static const int waterLogTypeId = 1;
  static const int reminderTypeId = 2;

  // Weight conversion
  static const double kgToLbs = 2.20462;

  // Water calculation: ~35ml per kg of body weight
  static const double mlPerKg = 35.0;
}

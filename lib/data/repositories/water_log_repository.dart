import 'package:hive/hive.dart';
import '../models/water_log.dart';
import '../../core/constants/app_constants.dart';

class WaterLogRepository {
  late Box<WaterLog> _box;

  Future<void> init() async {
    _box = await Hive.openBox<WaterLog>(AppConstants.waterLogBox);
  }

  Future<void> addLog(WaterLog log) async {
    await _box.put(log.id, log);
  }

  Future<void> deleteLog(String id) async {
    final log = _box.get(id);
    if (log != null) {
      log.deletedAt = DateTime.now();
      await log.save();
    }
  }

  /// Permanently delete items that have been synced as deletions
  Future<void> purgeDeletedLogs() async {
    final toDelete = _box.values
        .where((log) => log.deletedAt != null)
        .map((log) => log.id)
        .toList();
    for (final id in toDelete) {
      await _box.delete(id);
    }
  }

  List<WaterLog> getAllLogs() {
    return _box.values.where((log) => log.deletedAt == null).toList();
  }

  List<WaterLog> getTodayLogs() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _box.values
        .where(
          (log) => log.deletedAt == null && log.timestamp.isAfter(startOfDay),
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  int getTodayIntake() {
    return getTodayLogs().fold(0, (sum, log) => sum + log.amountMl);
  }

  List<WaterLog> getLogsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _box.values
        .where(
          (log) =>
              log.deletedAt == null &&
              log.timestamp.isAfter(startOfDay) &&
              log.timestamp.isBefore(endOfDay),
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<WaterLog> getLogsInRange(DateTime start, DateTime end) {
    return _box.values
        .where(
          (log) =>
              log.deletedAt == null &&
              log.timestamp.isAfter(start) &&
              log.timestamp.isBefore(end),
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Map<int, int> getWeeklyData() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final Map<int, int> weekData = {};

    for (int i = 0; i < 7; i++) {
      final day = DateTime(monday.year, monday.month, monday.day + i);
      final logs = getLogsForDate(day);
      weekData[i] = logs.fold(0, (sum, log) => sum + log.amountMl);
    }
    return weekData;
  }

  int getStreak(int dailyGoal) {
    int streak = 0;
    final now = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final date = now.subtract(Duration(days: i + 1));
      final dayLogs = getLogsForDate(date);
      final dayTotal = dayLogs.fold(0, (sum, log) => sum + log.amountMl);
      if (dayTotal >= dailyGoal) {
        streak++;
      } else {
        break;
      }
    }

    // Check today too
    final todayTotal = getTodayIntake();
    if (todayTotal >= dailyGoal) {
      streak++;
    }

    return streak;
  }

  double getWeeklyAverage() {
    final weekData = getWeeklyData();
    final totalDays = weekData.entries.where((e) => e.value > 0).length;
    if (totalDays == 0) return 0;
    final totalMl = weekData.values.fold(0, (sum, val) => sum + val);
    return totalMl / totalDays;
  }

  Map<int, int> getMonthlyData() {
    final now = DateTime.now();
    final totalDays = DateTime(now.year, now.month + 1, 0).day;
    final Map<int, int> monthData = {};

    for (int i = 1; i <= totalDays; i++) {
      final day = DateTime(now.year, now.month, i);
      final logs = getLogsForDate(day);
      monthData[i] = logs.fold(0, (sum, log) => sum + log.amountMl);
    }
    return monthData;
  }

  Map<int, int> getYearlyData() {
    final now = DateTime.now();
    final Map<int, int> yearlyData = {};

    for (int month = 1; month <= 12; month++) {
      final startOfMonth = DateTime(now.year, month, 1);
      final endOfMonth = DateTime(now.year, month + 1, 0, 23, 59, 59);
      final logs = getLogsInRange(startOfMonth, endOfMonth);
      yearlyData[month - 1] = logs.fold(0, (sum, log) => sum + log.amountMl);
    }
    return yearlyData;
  }
}

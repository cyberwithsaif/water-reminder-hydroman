import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/water_log.dart';
import '../data/repositories/water_log_repository.dart';
import 'user_provider.dart';

const _uuid = Uuid();

// Repository provider
final waterLogRepositoryProvider = Provider<WaterLogRepository>((ref) {
  return WaterLogRepository();
});

// Today's logs
final todayLogsProvider =
    StateNotifierProvider<TodayLogsNotifier, List<WaterLog>>((ref) {
      final repo = ref.watch(waterLogRepositoryProvider);
      return TodayLogsNotifier(repo);
    });

// Today's total intake
final todayIntakeProvider = Provider<int>((ref) {
  final logs = ref.watch(todayLogsProvider);
  return logs.fold(0, (sum, log) => sum + log.amountMl);
});

// Progress percentage
final progressProvider = Provider<double>((ref) {
  final intake = ref.watch(todayIntakeProvider);
  final profile = ref.watch(userProfileProvider);
  final goal = profile?.dailyGoalMl ?? 2500;
  return (intake / goal).clamp(0.0, 1.0);
});

// Streak
final streakProvider = Provider<int>((ref) {
  final repo = ref.watch(waterLogRepositoryProvider);
  final profile = ref.watch(userProfileProvider);
  final goal = profile?.dailyGoalMl ?? 2500;
  // Watch todayLogs to recompute when logs change
  ref.watch(todayLogsProvider);
  return repo.getStreak(goal);
});

// Weekly average
final weeklyAverageProvider = Provider<double>((ref) {
  final repo = ref.watch(waterLogRepositoryProvider);
  // Watch todayLogs to recompute when logs change
  ref.watch(todayLogsProvider);
  return repo.getWeeklyAverage();
});

// Weekly data for chart
final weeklyDataProvider = Provider<Map<int, int>>((ref) {
  final repo = ref.watch(waterLogRepositoryProvider);
  // Watch todayLogs to recompute when logs change
  ref.watch(todayLogsProvider);
  return repo.getWeeklyData();
});

// Monthly data for chart
final monthlyDataProvider = Provider<Map<int, int>>((ref) {
  final repo = ref.watch(waterLogRepositoryProvider);
  // Watch todayLogs to recompute when logs change
  ref.watch(todayLogsProvider);
  return repo.getMonthlyData();
});

// Yearly data for chart
final yearlyDataProvider = Provider<Map<int, int>>((ref) {
  final repo = ref.watch(waterLogRepositoryProvider);
  // Watch todayLogs to recompute when logs change
  ref.watch(todayLogsProvider);
  return repo.getYearlyData();
});

// Logs for specific date
final logsForDateProvider = StateProvider.family<List<WaterLog>, DateTime>((
  ref,
  date,
) {
  final repo = ref.watch(waterLogRepositoryProvider);
  // Re-read when todayLogs changes (to pick up additions/deletions)
  ref.watch(todayLogsProvider);
  return repo.getLogsForDate(date);
});

class TodayLogsNotifier extends StateNotifier<List<WaterLog>> {
  final WaterLogRepository _repo;

  TodayLogsNotifier(this._repo) : super([]);

  void load() {
    state = _repo.getTodayLogs();
  }

  Future<void> addWater(int amountMl, {String cupType = 'glass'}) async {
    final log = WaterLog(
      id: _uuid.v4(),
      amountMl: amountMl,
      timestamp: DateTime.now(),
      cupType: cupType,
    );
    await _repo.addLog(log);
    state = _repo.getTodayLogs();
  }

  Future<void> removeLog(String id) async {
    await _repo.deleteLog(id);
    state = _repo.getTodayLogs();
  }

  Future<void> removeLastLog() async {
    if (state.isNotEmpty) {
      // state is sorted by timestamp desc, so first one is the last added
      await _repo.deleteLog(state.first.id);
      state = _repo.getTodayLogs();
    }
  }
}

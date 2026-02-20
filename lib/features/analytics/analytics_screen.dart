import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/water_log_provider.dart';
import '../../providers/user_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _selectedRange = 'This Week';
  DateTime _historyDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final weeklyData = ref.watch(weeklyDataProvider);
    final yearlyData = ref.watch(yearlyDataProvider);
    final streak = ref.watch(streakProvider);
    final weeklyAvg = ref.watch(weeklyAverageProvider);
    final profile = ref.watch(userProfileProvider);
    final goal = profile?.dailyGoalMl ?? 2500;
    final todayLogs = ref.watch(todayLogsProvider);
    final historyLogs = ref.watch(logsForDateProvider(_historyDate));

    final isWeekly = _selectedRange == 'This Week';
    final chartData = isWeekly ? weeklyData : yearlyData;

    // Calculate completion percentage based on range
    final totalDaysInRange = isWeekly ? 7 : 12; // Week vs Year (Months)
    final daysCompleted = chartData.values.where((v) => v >= goal).length;
    final completionPct = (daysCompleted / totalDaysInRange * 100).round();

    // Calculate dynamic maxY to prevent overflow
    final maxValue = chartData.values.isEmpty
        ? goal.toDouble()
        : chartData.values.reduce((a, b) => a > b ? a : b).toDouble();
    final dynamicMaxY = maxValue > 0 ? maxValue * 1.2 : goal.toDouble() * 1.2;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text(
                  'Drinking History',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Date range selector
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: ['This Week', 'This Month'].map((range) {
                      final isSelected = _selectedRange == range;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRange = range),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                range,
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textTertiary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Chart
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: dynamicMaxY,
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (isWeekly) {
                                      const days = [
                                        'Mon',
                                        'Tue',
                                        'Wed',
                                        'Thu',
                                        'Fri',
                                        'Sat',
                                        'Sun',
                                      ];
                                      if (value.toInt() >= days.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          days[value.toInt()],
                                          style: GoogleFonts.manrope(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                      );
                                    } else {
                                      // Monthly/Yearly (Months)
                                      const months = [
                                        'Jan',
                                        'Feb',
                                        'Mar',
                                        'Apr',
                                        'May',
                                        'Jun',
                                        'Jul',
                                        'Aug',
                                        'Sep',
                                        'Oct',
                                        'Nov',
                                        'Dec',
                                      ];
                                      if (value.toInt() >= months.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          months[value.toInt()],
                                          style: GoogleFonts.manrope(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: chartData.entries
                                .map(
                                  (entry) => BarChartGroupData(
                                    x: entry.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: entry.value.toDouble(),
                                        color:
                                            (isWeekly == false ||
                                                entry.value >= goal)
                                            ? AppColors.primary
                                            : AppColors.primary.withValues(
                                                alpha: 0.4,
                                              ),
                                        width: isWeekly ? 22 : 10,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          topRight: Radius.circular(4),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Goal line legend
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Goal: ${goal}ml',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Stats cards
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Daily Average',
                        value: '${weeklyAvg.round()} ml',
                        icon: Icons.analytics,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Streak',
                        value: '$streak Days',
                        icon: Icons.local_fire_department,
                        color: AppColors.streak,
                      ),
                    ),
                  ],
                ),
              ),

              // Recent History
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent History',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _historyDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _historyDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_month, size: 16),
                      label: Text(
                        DateFormat('d MMM').format(_historyDate),
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (historyLogs.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.water_drop_outlined,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No drinks logged today',
                          style: GoogleFonts.manrope(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...historyLogs.map(
                  (log) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.shade50,
                            ),
                            child: Icon(
                              _getCupIcon(log.cupType),
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${log.amountMl} ml',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  DateFormat('h:mm a').format(log.timestamp),
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            log.cupType,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Bottom padding for navigation bar and ad
              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCupIcon(String cupType) {
    switch (cupType) {
      case 'espresso':
        return Icons.coffee;
      case 'glass':
        return Icons.water_drop;
      case 'bottle':
        return Icons.water;
      case 'sports':
        return Icons.sports_gymnastics;
      default:
        return Icons.water_drop;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/water_log_provider.dart';
import '../../providers/user_provider.dart';

class ReminderPromptScreen extends ConsumerWidget {
  const ReminderPromptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayIntake = ref.watch(todayIntakeProvider);
    final profile = ref.watch(userProfileProvider);
    final goal = profile?.dailyGoalMl ?? 2500;
    final remaining = (goal - todayIntake).clamp(0, goal);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Mascot / water drop animation
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                '💧 Time to Hydrate!',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                remaining > 0
                    ? 'You still need ${remaining}ml to reach your goal today.'
                    : 'Great job! You\'ve reached your daily goal! 🎉',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 16),

              // Progress bar
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: AppColors.progressBg,
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (todayIntake / goal).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '${todayIntake}ml / ${goal}ml',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),

              // Quick-log button (250ml)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref
                        .read(todayLogsProvider.notifier)
                        .addWater(250, cupType: 'glass');
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.local_drink, size: 22),
                  label: Text(
                    'Drink 250ml',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // More options row
              Row(
                children: [
                  // Log custom amount
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/cup-selection');
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          'Custom',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Snooze 15 min
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Snoozed for 15 minutes'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.snooze, size: 18),
                        label: Text(
                          'Snooze',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.orange.shade400),
                          foregroundColor: Colors.orange.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Skip
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Skip this reminder',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

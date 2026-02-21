import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/user_provider.dart';

class DailyGoalScreen extends ConsumerStatefulWidget {
  const DailyGoalScreen({super.key});

  @override
  ConsumerState<DailyGoalScreen> createState() => _DailyGoalScreenState();
}

class _DailyGoalScreenState extends ConsumerState<DailyGoalScreen> {
  late int _goal;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _goal = profile?.dailyGoalMl ?? AppConstants.defaultGoalMl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Daily Goal',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),

            // Goal display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_goal',
                  style: GoogleFonts.manrope(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'ml',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Slider
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 12,
                activeTrackColor: Theme.of(context).primaryColor,
                inactiveTrackColor: Colors.grey.shade100,
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 16,
                  elevation: 4,
                ),
                overlayColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: _goal.toDouble(),
                min: AppConstants.minGoalMl.toDouble(),
                max: AppConstants.maxGoalMl.toDouble(),
                divisions:
                    (AppConstants.maxGoalMl - AppConstants.minGoalMl) ~/
                    AppConstants.goalStepMl,
                onChanged: (val) => setState(() => _goal = val.round()),
              ),
            ),

            const SizedBox(height: 24),

            // +/- buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStepButton(Icons.remove, () {
                  if (_goal > AppConstants.minGoalMl) {
                    setState(() => _goal -= AppConstants.goalStepMl);
                  }
                }),
                _buildStepButton(Icons.add, () {
                  if (_goal < AppConstants.maxGoalMl) {
                    setState(() => _goal += AppConstants.goalStepMl);
                  }
                }),
              ],
            ),

            const Spacer(),

            // Save button
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(userProfileProvider.notifier).updateGoal(_goal);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Update Goal',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cardBorder),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 28, color: AppColors.textSecondary),
      ),
    );
  }
}

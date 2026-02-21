import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import '../../providers/water_log_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../core/widgets/banner_ad_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intake = ref.watch(todayIntakeProvider);
    final progress = ref.watch(progressProvider);
    final profile = ref.watch(userProfileProvider);
    final streak = ref.watch(streakProvider);
    final weeklyAvg = ref.watch(weeklyAverageProvider);
    final goal = profile?.dailyGoalMl ?? 2500;
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMM').format(now);
    final greeting = now.hour < 12
        ? 'Good Morning'
        : (now.hour < 17 ? 'Good Afternoon' : 'Good Evening');

    final nextReminder = ref.watch(nextReminderProvider);
    final notificationsEnabled = profile?.notificationsEnabled ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateStr,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '$greeting, ${profile?.name.isNotEmpty == true ? profile!.name : 'User'}',
                            style: GoogleFonts.manrope(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.stars,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${profile?.hydroCoins ?? 0} HC',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Progress circle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: WaterProgressIndicator(
                  progress: progress,
                  intake: intake,
                  goal: goal,
                ),
              ),

              // Stats row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(
                      label: 'Streak',
                      value: '$streak Days',
                      icon: Icons.local_fire_department,
                      iconColor: AppColors.streak,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade200,
                    ),
                    _StatItem(
                      label: 'Average',
                      value: '${weeklyAvg.round()} ml',
                      icon: Icons.show_chart,
                      iconColor: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick Add section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quick Add',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            ref
                                .read(todayLogsProvider.notifier)
                                .removeLastLog();
                          },
                          icon: const Icon(Icons.undo, size: 16),
                          label: Text(
                            'Minus',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final defaultCup = profile?.defaultCupMl ?? 250;
                        final defaultIcon = defaultCup <= 100
                            ? Icons.coffee
                            : defaultCup <= 250
                            ? Icons.local_drink
                            : defaultCup <= 500
                            ? Icons.water
                            : Icons.sports_gymnastics;
                        final defaultLabel = defaultCup <= 100
                            ? 'espresso'
                            : defaultCup <= 250
                            ? 'glass'
                            : defaultCup <= 500
                            ? 'bottle'
                            : 'sports';
                        return Row(
                          children: [
                            Expanded(
                              child: _QuickAddButton(
                                icon: defaultIcon,
                                amount: defaultCup,
                                isPrimary: true,
                                onTap: () {
                                  ref
                                      .read(todayLogsProvider.notifier)
                                      .addWater(
                                        defaultCup,
                                        cupType: defaultLabel,
                                      );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickAddButton(
                                icon: Icons.water,
                                amount: 500,
                                isPrimary: false,
                                onTap: () {
                                  ref
                                      .read(todayLogsProvider.notifier)
                                      .addWater(500, cupType: 'bottle');
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/cup-selection',
                              ),
                              child: Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 2,
                                    strokeAlign: BorderSide.strokeAlignInside,
                                  ),
                                  color: Colors.grey.shade50,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 28,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Next reminder card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, '/reminder-schedule'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            Icons.notifications_active,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Next Reminder',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                nextReminder != null
                                    ? 'Scheduled for ${nextReminder.time}'
                                    : (notificationsEnabled
                                          ? 'No reminders scheduled'
                                          : 'Notifications are off'),
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.textTertiary,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tip card
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        Colors.white,
                      ],
                    ),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb,
                                  color: Theme.of(context).primaryColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'HYDROMAN TIP',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).primaryColor,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              progress >= 0.5
                                  ? 'Great job! You\'re halfway there. Drinking water before meals can help you feel fuller.'
                                  : 'Start your day with a glass of water to kickstart your metabolism!',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          Icons.water_drop,
                          color: Theme.of(context).primaryColor,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Banner Ad
              const BannerAdWidget(),

              // Bottom padding for navigation bar and ad
              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  final IconData icon;
  final int amount;
  final bool isPrimary;
  final VoidCallback onTap;

  const _QuickAddButton({
    required this.icon,
    required this.amount,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 92,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isPrimary
              ? Theme.of(context).primaryColor
              : Colors.grey.shade100,
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isPrimary ? Colors.white : Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              '+${amount}ml',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isPrimary
                    ? Colors.white
                    : Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WaterProgressIndicator extends StatefulWidget {
  final double progress;
  final int intake;
  final int goal;

  const WaterProgressIndicator({
    super.key,
    required this.progress,
    required this.intake,
    required this.goal,
  });

  @override
  State<WaterProgressIndicator> createState() => _WaterProgressIndicatorState();
}

class _WaterProgressIndicatorState extends State<WaterProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(240, 240),
                painter: _WaterFillPainter(
                  progress: widget.progress,
                  waveValue: _controller.value,
                  backgroundColor: Colors.grey.shade100,
                  waterColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.15),
                  progressColor: Theme.of(context).primaryColor,
                ),
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.water_drop,
                color: Theme.of(context).primaryColor,
                size: 36,
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.intake}',
                style: GoogleFonts.manrope(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              Text(
                'ml',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Goal: ${widget.goal}ml',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaterFillPainter extends CustomPainter {
  final double progress;
  final double waveValue;
  final Color backgroundColor;
  final Color waterColor;
  final Color progressColor;

  _WaterFillPainter({
    required this.progress,
    required this.waveValue,
    required this.backgroundColor,
    required this.waterColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 10.0;

    // 1. Background circle rim
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // 2. Water fill inside (clipping to circle)
    final clipPath = Path()
      ..addOval(
        Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2)),
      );
    canvas.save();
    canvas.clipPath(clipPath);

    final waterHeight = (radius * 2) * progress.clamp(0.0, 1.0);
    final fillTop = (center.dy + radius) - waterHeight;

    final waterPath = Path();
    waterPath.moveTo(center.dx - radius, center.dy + radius);

    // Wave animation
    for (double i = 0; i <= radius * 2; i++) {
      final x = (center.dx - radius) + i;
      final y =
          fillTop +
          math.sin((i / radius * math.pi) + (waveValue * 2 * math.pi)) * 6;
      waterPath.lineTo(x, y);
    }

    waterPath.lineTo(center.dx + radius, center.dy + radius);
    waterPath.close();

    final waterPaint = Paint()..color = waterColor;
    canvas.drawPath(waterPath, waterPaint);
    canvas.restore();

    // 3. Progress arc on the rim
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterFillPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.waveValue != waveValue;
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  _ProgressRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 10.0;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

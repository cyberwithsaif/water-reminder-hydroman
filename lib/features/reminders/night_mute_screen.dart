import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/user_provider.dart';

class NightMuteScreen extends ConsumerWidget {
  const NightMuteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = ref.watch(nightMuteEnabledProvider);
    final bedtime = ref.watch(nightMuteBedtimeProvider);
    final wakeTime = ref.watch(nightMuteWakeTimeProvider);
    final repeatDays = ref.watch(nightMuteRepeatDaysProvider);
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Night Mute',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enable card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: isEnabled
                      ? [
                          AppColors.primary.withValues(alpha: 0.05),
                          AppColors.primary.withValues(alpha: 0.1),
                        ]
                      : [Colors.grey.shade50, Colors.grey.shade100],
                ),
                border: Border.all(
                  color: isEnabled
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : AppColors.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isEnabled
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : Colors.grey.shade200,
                    ),
                    child: Icon(
                      Icons.nightlight_round,
                      color: isEnabled
                          ? AppColors.primary
                          : AppColors.textTertiary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mute Notifications',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Silence reminders during sleep',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isEnabled,
                    onChanged: (val) async {
                      await ref
                          .read(userProfileProvider.notifier)
                          .updateNightMute(isEnabled: val);
                      ref.read(remindersProvider.notifier).scheduleNotifications();
                    },
                    activeTrackColor: AppColors.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Time settings
            Text(
              'SLEEP SCHEDULE',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _TimePickerCard(
                    label: 'Bedtime',
                    icon: Icons.bedtime,
                    time: bedtime,
                    onTap: () => _pickTime(context, ref, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TimePickerCard(
                    label: 'Wake Up',
                    icon: Icons.wb_sunny,
                    time: wakeTime,
                    onTap: () => _pickTime(context, ref, false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Repeat days
            Text(
              'REPEAT DAYS',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final isActive = repeatDays[index];
                return GestureDetector(
                  onTap: () async {
                    final newDays = List<bool>.from(repeatDays);
                    newDays[index] = !newDays[index];
                    await ref
                        .read(userProfileProvider.notifier)
                        .updateNightMute(repeatDays: newDays);
                    ref.read(remindersProvider.notifier).scheduleNotifications();
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? AppColors.primary
                          : Colors.grey.shade100,
                    ),
                    child: Center(
                      child: Text(
                        dayLabels[index][0],
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    bool isBedtime,
  ) async {
    final currentTime = isBedtime
        ? ref.read(nightMuteBedtimeProvider)
        : ref.read(nightMuteWakeTimeProvider);
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (isBedtime) {
        await ref
            .read(userProfileProvider.notifier)
            .updateNightMute(bedtime: timeStr);
      } else {
        await ref
            .read(userProfileProvider.notifier)
            .updateNightMute(wakeTime: timeStr);
      }
      ref.read(remindersProvider.notifier).scheduleNotifications();
    }
  }
}

class _TimePickerCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String time;
  final VoidCallback onTap;

  const _TimePickerCard({
    required this.label,
    required this.icon,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                children: [
                  TextSpan(text: '$displayHour:$minute '),
                  TextSpan(
                    text: period,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

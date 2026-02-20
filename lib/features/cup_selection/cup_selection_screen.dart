import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/water_log_provider.dart';
import '../../providers/user_provider.dart';

class CupSelectionScreen extends ConsumerWidget {
  const CupSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intake = ref.watch(todayIntakeProvider);
    final profile = ref.watch(userProfileProvider);
    final goal = profile?.dailyGoalMl ?? 2500;
    final progress = intake / goal;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Log Drink',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Progress summary
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        children: [
                          TextSpan(text: '${_formatNumber(intake)} '),
                          TextSpan(
                            text: '/ ${_formatNumber(goal)} ml',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          // Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select container size',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.0,
                      children: [
                        _CupCard(
                          icon: Icons.coffee,
                          size: '100 ml',
                          label: 'Espresso',
                          onTap: () =>
                              _addAndPop(context, ref, 100, 'espresso'),
                        ),
                        _CupCard(
                          icon: Icons.water_drop,
                          size: '250 ml',
                          label: 'Glass',
                          isSelected: false,
                          onTap: () => _addAndPop(context, ref, 250, 'glass'),
                        ),
                        _CupCard(
                          icon: Icons.water,
                          size: '500 ml',
                          label: 'Bottle',
                          onTap: () => _addAndPop(context, ref, 500, 'bottle'),
                        ),
                        _CupCard(
                          icon: Icons.sports_gymnastics,
                          size: '750 ml',
                          label: 'Sports',
                          onTap: () => _addAndPop(context, ref, 750, 'sports'),
                        ),
                      ],
                    ),
                  ),

                  // Custom amount
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _showCustomAmountDialog(context, ref),
                      icon: const Icon(Icons.edit, size: 20),
                      label: Text(
                        'Enter Custom Amount',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addAndPop(
    BuildContext context,
    WidgetRef ref,
    int amount,
    String cupType,
  ) {
    ref.read(todayLogsProvider.notifier).addWater(amount, cupType: cupType);
    Navigator.pop(context);
  }

  void _showCustomAmountDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Custom Amount',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            suffixText: 'ml',
            hintText: 'Enter amount',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(controller.text);
              if (amount != null && amount > 0) {
                ref
                    .read(todayLogsProvider.notifier)
                    .addWater(amount, cupType: 'custom');
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)},${(number % 1000).toString().padLeft(3, '0').substring(0, 3)}';
    }
    return number.toString();
  }
}

class _CupCard extends StatelessWidget {
  final IconData icon;
  final String size;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CupCard({
    required this.icon,
    required this.size,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white,
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                top: 12,
                right: 12,
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.white : Colors.grey.shade50,
                    ),
                    child: Icon(icon, size: 28, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    size,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      letterSpacing: 1,
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

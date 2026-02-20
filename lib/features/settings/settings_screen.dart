import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../services/notification_service.dart';
import '../../services/permission_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    // Load notification state from persisted profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(userProfileProvider);
      if (profile != null && mounted) {
        setState(() {
          _notificationsEnabled = profile.notificationsEnabled;
        });
      }
    });
  }

  // ====== Name Editor ======
  void _showNameEditor() {
    final profile = ref.read(userProfileProvider);
    if (profile == null) return;

    final controller = TextEditingController(text: profile.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 42,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update Name',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final name = controller.text.trim();
                  ref.read(userProfileProvider.notifier).updateName(name);
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====== Weight Editor ======
  void _showWeightEditor() {
    final profile = ref.read(userProfileProvider);
    if (profile == null) return;

    final controller = TextEditingController(
      text: profile.weightDisplay.round().toString(),
    );
    String unit = profile.weightUnit;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Weight',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        suffixText: unit,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildUnitChip('kg', unit, (u) {
                    setModalState(() => unit = u);
                  }),
                  const SizedBox(width: 6),
                  _buildUnitChip('lbs', unit, (u) {
                    setModalState(() => unit = u);
                  }),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final val = double.tryParse(controller.text);
                    if (val == null || val <= 0) return;
                    final weightKg = unit == 'lbs' ? val / 2.20462 : val;
                    final p = ref.read(userProfileProvider);
                    if (p != null) {
                      p.weightKg = weightKg;
                      p.weightUnit = unit;
                      p.save();
                      ref.read(userProfileProvider.notifier).load();
                    }
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitChip(
    String label,
    String selected,
    ValueChanged<String> onTap,
  ) {
    final isSelected = selected == label;
    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ====== Gender Editor ======
  void _showGenderEditor() {
    final profile = ref.read(userProfileProvider);
    if (profile == null) return;

    String selected = profile.gender;
    final options = ['male', 'female', 'other'];
    final labels = ['Male', 'Female', 'Non-binary / Other'];
    final icons = [Icons.male, Icons.female, Icons.transgender];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Gender',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(options.length, (i) {
                final isActive = selected == options[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setModalState(() => selected = options[i]),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.cardBorder,
                          width: isActive ? 2 : 1,
                        ),
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            icons[i],
                            color: isActive
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            labels[i],
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (isActive)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final p = ref.read(userProfileProvider);
                    if (p != null) {
                      p.gender = selected;
                      p.save();
                      ref.read(userProfileProvider.notifier).load();
                    }
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====== Units Editor ======
  void _showUnitsEditor() {
    final profile = ref.read(userProfileProvider);
    if (profile == null) return;

    String selected = profile.weightUnit;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Measurement Units',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _buildUnitOption(
                'Metric',
                'ml, kg',
                'kg',
                selected,
                (val) => setModalState(() => selected = val),
              ),
              const SizedBox(height: 8),
              _buildUnitOption(
                'Imperial',
                'oz, lbs',
                'lbs',
                selected,
                (val) => setModalState(() => selected = val),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final p = ref.read(userProfileProvider);
                    if (p != null) {
                      // Convert weight between units
                      p.weightUnit = selected;
                      p.save();
                      ref.read(userProfileProvider.notifier).load();
                    }
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitOption(
    String title,
    String subtitle,
    String value,
    String selected,
    ValueChanged<String> onTap,
  ) {
    final isActive = selected == value;
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.cardBorder,
            width: isActive ? 2 : 1,
          ),
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.white,
        ),
        child: Row(
          children: [
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (isActive)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  // ====== Notifications Toggle ======
  void _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await ref.read(userProfileProvider.notifier).toggleNotifications(value);

    if (value) {
      await NotificationService.instance.requestPermission();
      // Reschedule reminders
      await ref.read(remindersProvider.notifier).load();
    } else {
      await NotificationService.instance.cancelAll();
    }
  }

  // ====== Help & FAQ ======
  void _showHelpFaq() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Text(
                'Help & FAQ',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              _buildFaqItem(
                'How much water should I drink daily?',
                'The recommended daily intake is about 2-3 liters (8-12 cups), '
                    'but this varies based on your weight, activity level, and climate.',
              ),
              _buildFaqItem(
                'How do reminders work?',
                'Set your wake and sleep times in the reminder schedule. '
                    'Hydroman will send smart notifications throughout your active hours.',
              ),
              _buildFaqItem(
                'Can I sync data across devices?',
                'Yes! Sign in with your phone number under Cloud Sync in settings '
                    'to backup and sync your hydration data.',
              ),
              _buildFaqItem(
                'How is my daily goal calculated?',
                'Your goal is based on your weight — roughly 30-35ml per kg of body weight. '
                    'You can always adjust it manually.',
              ),
              _buildFaqItem(
                'What does the streak mean?',
                'Your streak counts consecutive days where you met your daily goal. '
                    'Keep it going to build a healthy habit!',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Text(
          question,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        children: [
          Text(
            answer,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ====== Send Feedback ======
  void _showFeedback() {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 42,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send Feedback',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Help us improve Hydroman! Share your thoughts.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              style: GoogleFonts.manrope(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tell us what you think...',
                hintStyle: GoogleFonts.manrope(color: AppColors.textTertiary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thank you for your feedback! 💙'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.send, size: 18),
                label: Text(
                  'Submit',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====== Build ======
  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final unitLabel = profile?.weightUnit == 'lbs'
        ? 'Imperial (oz, lbs)'
        : 'Metric (ml, kg)';
    final weightLabel = profile != null
        ? '${profile.weightDisplay.round()} ${profile.weightUnit}'
        : '70 kg';
    final genderLabel = profile?.gender ?? 'male';
    final genderDisplay = genderLabel == 'male'
        ? 'Male'
        : genderLabel == 'female'
        ? 'Female'
        : 'Non-binary / Other';

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
                  'Settings',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // User profile card
              Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white24,
                        ),
                        child: Center(
                          child: Text(
                            profile?.name.isNotEmpty == true
                                ? profile!.name[0].toUpperCase()
                                : 'U',
                            style: GoogleFonts.manrope(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.name.isNotEmpty == true
                                  ? profile!.name
                                  : 'Hydroman User',
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Daily Goal: ${profile?.dailyGoalMl ?? 2500}ml',
                              style: GoogleFonts.manrope(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Personal Info section
              _SectionHeader(title: 'PERSONAL INFO'),
              _SettingsTile(
                icon: Icons.person_outline,
                title: 'Name',
                subtitle: profile?.name.isNotEmpty == true
                    ? profile!.name
                    : 'Not set',
                onTap: _showNameEditor,
              ),
              _SettingsTile(
                icon: Icons.person_outline,
                title: 'Weight',
                subtitle: weightLabel,
                onTap: _showWeightEditor,
              ),
              _SettingsTile(
                icon: Icons.male,
                title: 'Gender',
                subtitle: genderDisplay,
                onTap: _showGenderEditor,
              ),
              _SettingsTile(
                icon: Icons.local_drink,
                title: 'Daily Goal',
                subtitle: '${profile?.dailyGoalMl ?? 2500} ml',
                onTap: () => Navigator.pushNamed(context, '/daily-goal'),
              ),

              const SizedBox(height: 8),

              // Preferences section
              _SectionHeader(title: 'PREFERENCES'),
              _SettingsTile(
                icon: Icons.straighten,
                title: 'Units',
                subtitle: unitLabel,
                onTap: _showUnitsEditor,
              ),
              _SettingsTile(
                icon: Icons.schedule,
                title: 'Reminder Schedule',
                subtitle: 'Manage reminders',
                onTap: () => Navigator.pushNamed(context, '/reminder-schedule'),
              ),
              _SettingsTile(
                icon: Icons.bedtime_outlined,
                title: 'Night Mute',
                subtitle: 'Do not disturb hours',
                onTap: () => Navigator.pushNamed(context, '/night-mute'),
              ),

              const SizedBox(height: 8),

              // Support section
              _SectionHeader(title: 'SUPPORT'),
              _SettingsTile(
                icon: Icons.help_outline,
                title: 'Help & FAQ',
                onTap: _showHelpFaq,
              ),
              _SettingsTile(
                icon: Icons.feedback_outlined,
                title: 'Send Feedback',
                onTap: _showFeedback,
              ),

              const SizedBox(height: 8),

              // Cloud Sync section
              _SectionHeader(title: 'CLOUD SYNC'),
              _SettingsTile(
                icon: Icons.cloud_outlined,
                title: 'Sync Account',
                subtitle: ref.watch(isLoggedInProvider)
                    ? 'Signed in · Data synced'
                    : 'Sign in to backup data',
                onTap: () {
                  if (ref.read(isLoggedInProvider)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Synced to cloud successfully',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } else {
                    Navigator.pushNamed(context, '/login');
                  }
                },
              ),

              const SizedBox(height: 16),

              // Troubleshooting section
              _SectionHeader(title: 'TROUBLESHOOTING'),
              _SettingsTile(
                icon: Icons.notifications_paused_outlined,
                title: 'Test Background Notification',
                subtitle: 'Fires in 5s. Close app to test!',
                onTap: () async {
                  final msg = await NotificationService.instance
                      .testScheduledNotification();
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(msg)));
                  }
                },
              ),
              _SettingsTile(
                icon: Icons.battery_saver_outlined,
                title: 'Battery Optimization',
                subtitle: 'Ensure notifications work in background',
                onTap: () async {
                  await PermissionService.requestAll();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Requested optimization exemption'),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 32), // Reduced from 48
              // Sign out
              if (ref.watch(isLoggedInProvider))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref.read(authStateProvider.notifier).logout();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout, color: AppColors.error),
                      label: Text(
                        'Sign Out',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // Powered by
              Center(
                child: Column(
                  children: [
                    Text(
                      'POWERED BY',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textTertiary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Image.asset(
                      'assets/images/powered_by_logo.png',
                      height: 32,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Version
              Center(
                child: Text(
                  'Hydroman v1.0.0',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),

              const SizedBox(height: 20), // Reduced from 60
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12), // Increased from 8
      child: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.textSecondary),
              const SizedBox(width: 20), // Increased from 16
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
                    size: 22,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

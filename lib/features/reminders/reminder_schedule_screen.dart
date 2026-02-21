import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/water_log_provider.dart';
import '../../data/models/reminder.dart';
import '../../core/widgets/banner_ad_widget.dart';

class ReminderScheduleScreen extends ConsumerStatefulWidget {
  const ReminderScheduleScreen({super.key});

  @override
  ConsumerState<ReminderScheduleScreen> createState() =>
      _ReminderScheduleScreenState();
}

class _ReminderScheduleScreenState
    extends ConsumerState<ReminderScheduleScreen> {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll(List<Reminder> reminders) {
    setState(() {
      if (_selectedIds.length == reminders.length) {
        _selectedIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedIds.addAll(reminders.map((r) => r.id));
        _isSelectionMode = true;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(remindersProvider);
    final intake = ref.watch(todayIntakeProvider);
    final profile = ref.watch(userProfileProvider);
    final goal = profile?.dailyGoalMl ?? 2500;
    final progress = (intake / goal).clamp(0.0, 1.0);

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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isSelectionMode
                          ? '${_selectedIds.length} Selected'
                          : 'Reminders',
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_isSelectionMode)
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _selectedIds.length == reminders.length
                                  ? Icons.deselect
                                  : Icons.select_all,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => _selectAll(reminders),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _showBulkDeleteConfirmation(
                              context,
                              ref,
                              _selectedIds.toList(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: _exitSelectionMode,
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.nightlight_round,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () =>
                                Navigator.pushNamed(context, '/night-mute'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Hero card (only show if not in selection mode or keep it for context?)
              // Let's hide it in selection mode to focus on the list
              if (!_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColorDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Goal',
                                style: GoogleFonts.manrope(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$intake / ${goal}ml',
                                style: GoogleFonts.manrope(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: Colors.white24,
                                  valueColor: const AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white24,
                          ),
                          child: Center(
                            child: Text(
                              '${(progress * 100).round()}%',
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Upcoming reminders label
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Text(
                  _isSelectionMode ? 'SELECT REMINDERS' : 'UPCOMING REMINDERS',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Reminder list
              ...reminders.map((reminder) {
                final isSelected = _selectedIds.contains(reminder.id);
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  child: InkWell(
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleSelection(reminder.id);
                      } else {
                        _showReminderEditor(context, ref, reminder);
                      }
                    },
                    onLongPress: () {
                      if (!_isSelectionMode) {
                        _toggleSelection(reminder.id);
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : AppColors.cardBorder,
                          width: isSelected ? 2 : 1,
                        ),
                        color: isSelected
                            ? Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.05)
                            : Colors.white,
                      ),
                      child: Row(
                        children: [
                          if (_isSelectionMode)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : AppColors.textTertiary,
                              ),
                            )
                          else
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: reminder.isEnabled
                                    ? Theme.of(
                                        context,
                                      ).primaryColor.withValues(alpha: 0.1)
                                    : Colors.grey.shade100,
                              ),
                              child: Icon(
                                Icons.notifications_active,
                                color: reminder.isEnabled
                                    ? Theme.of(context).primaryColor
                                    : AppColors.textTertiary,
                                size: 22,
                              ),
                            ),
                          if (!_isSelectionMode) const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reminder.time,
                                  style: GoogleFonts.manrope(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  reminder.label,
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!_isSelectionMode)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _showDeleteConfirmation(
                                      context,
                                      ref,
                                      reminder.id,
                                    );
                                  },
                                ),
                                Switch(
                                  value: reminder.isEnabled,
                                  onChanged: (val) {
                                    ref
                                        .read(remindersProvider.notifier)
                                        .toggleReminder(reminder.id);
                                  },
                                  activeTrackColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),

              const SizedBox(height: 16),

              // Banner Ad
              const BannerAdWidget(),

              // Bottom padding for navigation bar and ad
              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => _showReminderEditor(context, ref),
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  void _showReminderEditor(
    BuildContext context,
    WidgetRef ref, [
    Reminder? reminder,
  ]) async {
    final isEditing = reminder != null;
    final timeController = TextEditingController(
      text: isEditing ? reminder.time : '08:00',
    );
    final labelController = TextEditingController(
      text: isEditing ? reminder.label : '',
    );

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
          MediaQuery.of(ctx).viewInsets.bottom +
              MediaQuery.of(ctx).padding.bottom +
              24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edit Reminder' : 'Add Reminder',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () async {
                final parts = timeController.text.split(':');
                final initialTime = TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                );
                final picked = await showTimePicker(
                  context: context,
                  initialTime: initialTime,
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(alwaysUse24HourFormat: true),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  final h = picked.hour.toString().padLeft(2, '0');
                  final m = picked.minute.toString().padLeft(2, '0');
                  timeController.text = '$h:$m';
                }
              },
              child: IgnorePointer(
                child: TextField(
                  controller: timeController,
                  decoration: InputDecoration(
                    labelText: 'Time',
                    prefixIcon: const Icon(Icons.access_time),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: labelController,
              decoration: InputDecoration(
                labelText: 'Label (e.g. Afternoon Glass)',
                prefixIcon: const Icon(Icons.label_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final newReminder = Reminder(
                    id: isEditing
                        ? reminder.id
                        : DateTime.now().millisecondsSinceEpoch.toString(),
                    time: timeController.text,
                    label: labelController.text.isEmpty
                        ? 'Drink Water'
                        : labelController.text,
                    isEnabled: isEditing ? reminder.isEnabled : true,
                  );
                  final notifier = ref.read(remindersProvider.notifier);
                  notifier.addReminder(newReminder);
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    List<String> ids,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${ids.length} Reminders'),
        content: Text(
          'Are you sure you want to delete ${ids.length} selected reminders?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(remindersProvider.notifier).deleteReminders(ids);
              _exitSelectionMode();
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(remindersProvider.notifier).deleteReminder(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

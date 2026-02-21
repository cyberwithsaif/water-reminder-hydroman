import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../features/home/home_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/reminders/reminder_schedule_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/water_log_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../services/permission_service.dart';
import 'banner_ad_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppScaffold extends ConsumerStatefulWidget {
  const AppScaffold({super.key});

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  int _currentIndex = 0;
  Timer? _syncTimer;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    // Trigger auto-sync and permission request on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await PermissionService.requestAll();
      _performSync();
      // Start periodic sync every 10 seconds
      _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _performSync();
      });
    });
  }

  void _performSync() {
    if (_isSyncing) return;
    final isLoggedIn = ref.read(isLoggedInProvider);
    if (!isLoggedIn) return;

    _isSyncing = true;
    ref
        .read(syncServiceProvider)
        .syncAll(
          onComplete: () {
            if (!mounted) return;
            // Reload all providers with synced data
            ref.read(userProfileProvider.notifier).load();
            ref.read(todayLogsProvider.notifier).load();
            ref.read(remindersProvider.notifier).loadDataOnly();
          },
        )
        .whenComplete(() {
          _isSyncing = false;
        });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  final _pages = const [
    HomeScreen(),
    ReminderScheduleScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          final slideAnimation = Tween<Offset>(
            begin: const Offset(0.02, 0),
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slideAnimation, child: child),
          );
        },
        child: Container(
          key: ValueKey<int>(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AdMob Banner Ad
          const BannerAdWidget(),
          // Bottom Navigation Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.water_drop,
                      label: 'Home',
                      isSelected: _currentIndex == 0,
                      onTap: () => setState(() => _currentIndex = 0),
                    ),
                    _NavItem(
                      icon: Icons.calendar_today,
                      label: 'Schedule',
                      isSelected: _currentIndex == 1,
                      onTap: () => setState(() => _currentIndex = 1),
                    ),
                    _NavItem(
                      icon: Icons.bar_chart,
                      label: 'Analytics',
                      isSelected: _currentIndex == 2,
                      onTap: () => setState(() => _currentIndex = 2),
                    ),
                    _NavItem(
                      icon: Icons.settings,
                      label: 'Settings',
                      isSelected: _currentIndex == 3,
                      onTap: () => setState(() => _currentIndex = 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 26,
            color: isSelected ? primaryColor : AppColors.textTertiary,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? primaryColor : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

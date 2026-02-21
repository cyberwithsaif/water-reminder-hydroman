import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/reminders/reminder_schedule_screen.dart';
import 'features/reminders/night_mute_screen.dart';
import 'features/analytics/analytics_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/cup_selection/cup_selection_screen.dart';
import 'features/settings/daily_goal_screen.dart';
import 'core/widgets/app_scaffold.dart';
import 'features/auth/login_screen.dart';
import 'features/reminders/reminder_prompt_screen.dart';

import 'providers/theme_provider.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: HydromanApp()));
}

class HydromanApp extends ConsumerWidget {
  const HydromanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final darkTheme = ref.watch(darkThemeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hydroman',
      theme: theme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/main': (_) => const AppScaffold(),
        '/cup-selection': (_) => const CupSelectionScreen(),
        '/reminder-schedule': (_) => const ReminderScheduleScreen(),
        '/night-mute': (_) => const NightMuteScreen(),
        '/analytics': (_) => const AnalyticsScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/daily-goal': (_) => const DailyGoalScreen(),
        '/login': (_) => const LoginScreen(),
        '/reminder-prompt': (_) => const ReminderPromptScreen(),
      },
    );
  }
}

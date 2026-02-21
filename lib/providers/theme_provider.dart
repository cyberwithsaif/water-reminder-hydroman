import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import 'user_provider.dart';

final themeProvider = Provider<ThemeData>((ref) {
  final profile = ref.watch(userProfileProvider);
  final themeName = profile?.themeName ?? 'blue';

  Color primary;
  Color primaryDark;

  switch (themeName) {
    case 'orange':
      primary = AppColors.orangePrimary;
      primaryDark = AppColors.orangePrimaryDark;
      break;
    case 'green':
      primary = AppColors.greenPrimary;
      primaryDark = AppColors.greenPrimaryDark;
      break;
    default:
      primary = AppColors.primary;
      primaryDark = AppColors.primaryDark;
  }

  return AppTheme.getTheme(primary, primaryDark);
});

final darkThemeProvider = Provider<ThemeData>((ref) {
  final profile = ref.watch(userProfileProvider);
  final themeName = profile?.themeName ?? 'blue';

  Color primary;
  Color primaryDark;

  switch (themeName) {
    case 'orange':
      primary = AppColors.orangePrimary;
      primaryDark = AppColors.orangePrimaryDark;
      break;
    case 'green':
      primary = AppColors.greenPrimary;
      primaryDark = AppColors.greenPrimaryDark;
      break;
    default:
      primary = AppColors.primary;
      primaryDark = AppColors.primaryDark;
  }

  return AppTheme.getTheme(primary, primaryDark, isDark: true);
});

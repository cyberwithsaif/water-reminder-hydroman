import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  PermissionService._();

  static Future<void> requestAll() async {
    debugPrint('PermissionService: Requesting all permissions');

    // 1. Notification Permission (Android 13+)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // 2. Exact Alarm Permission (Android 12+)
    // This is required for scheduled notifications to be precise
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    // 3. Background / Battery Optimization Permission
    // Helps prevent the OS from killing the app's background tasks
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      // Note: This usually opens a system dialog or settings
      await Permission.ignoreBatteryOptimizations.request();
    }

    debugPrint('PermissionService: Permissions check complete');
  }

  static Future<bool> hasAllPermissions() async {
    final notification = await Permission.notification.isGranted;
    final alarm = await Permission.scheduleExactAlarm.isGranted;
    // Battery optimization is optional but recommended
    return notification && alarm;
  }
}

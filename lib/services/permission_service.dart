import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'notification_service.dart';

class PermissionService {
  PermissionService._();

  static Future<void> requestAll() async {
    debugPrint('PermissionService: Requesting all permissions');

    // 1. Notification & Exact Alarm Permissions
    // We use NotificationService's implementation as it's tailored for these
    await NotificationService.instance.requestPermission();

    // 2. Background / Battery Optimization Permission
    // Helps prevent the OS from killing the app's background tasks
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      debugPrint('PermissionService: Requesting ignoreBatteryOptimizations');
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

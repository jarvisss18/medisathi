import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Singleton service that wraps flutter_local_notifications v22+.
/// Handles: initialisation, permission requests, daily-repeating exact alarms,
/// and notification-tap navigation.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Optional callback so the app can navigate when a notification is tapped.
  static void Function(String? payload)? onNotificationTap;

  // ─── Initialise once ────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_isInitialized) return;

    // Set up the correct local timezone.
    tz.initializeTimeZones();
    try {
      // flutter_timezone v5.x: TimezoneInfo.identifier holds the IANA tz string.
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      // Fallback – leave as UTC.
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    // flutter_local_notifications v22 uses named parameter 'settings:'.
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap?.call(response.payload);
      },
    );

    // Request POST_NOTIFICATIONS + exact alarms permission on Android 13+.
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    _isInitialized = true;
  }

  static const MethodChannel _nativeAlarmChannel = MethodChannel('com.bugbusters.medisathi/alarm');

  // ─── Schedule / reschedule a daily repeating dose alarm ─────────────────────
  Future<void> scheduleDoseReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    bool dailyRepeat = true,
  }) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'medisathi_reminders_alarm',
      'Medication Alarm Reminders',
      channelDescription: 'High-priority full-screen dose alarms',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
    );
    const details = NotificationDetails(android: androidDetails);

    // Build the next occurrence of the requested time in local timezone.
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // Schedule native Android AlarmManager -> AlarmActivity
    // Automatically pops up green "Medicine Time!" screen when locked/sleeping,
    // or shows heads-up notification banner when user is in another app.
    try {
      final triggerMs = scheduled.millisecondsSinceEpoch;
      final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      final cleanName = title.replaceFirst('Time for ', '').replaceFirst(' 💊', '');
      await _nativeAlarmChannel.invokeMethod('scheduleAlarm', {
        'triggerMs': triggerMs,
        'medicineName': cleanName,
        'doseText': body,
        'timeStr': timeStr,
        'notifId': id,
      });
    } catch (e) {
      debugPrint('[NotificationService] native scheduleAlarm failed: $e');
      // Fallback to local notification
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduled,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: dailyRepeat ? DateTimeComponents.time : null,
          payload: 'reminder:$id',
        );
      } catch (_) {}
    }
  }

  // ─── Cancel a specific alarm ─────────────────────────────────────────────────
  Future<void> cancelReminder(int id) async {
    await init();
    await _plugin.cancel(id: id);
    try {
      await _nativeAlarmChannel.invokeMethod('cancelAlarm', {'notifId': id});
    } catch (_) {}
  }

  // ─── Cancel all alarms ───────────────────────────────────────────────────────
  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}

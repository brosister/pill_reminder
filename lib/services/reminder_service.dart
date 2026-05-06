import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderSettings {
  const ReminderSettings({
    required this.enabled,
    required this.slotTimes,
  });

  final bool enabled;
  final Map<String, int> slotTimes;

  ReminderSettings copyWith({
    bool? enabled,
    Map<String, int>? slotTimes,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      slotTimes: slotTimes ?? this.slotTimes,
    );
  }
}

class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  static const _enabledKey = 'pill_reminder_enabled';
  static const _slotTimesKey = 'pill_reminder_slot_times';
  static const _notificationBaseId = 5100;
  static const _notificationMaxCount = 64;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    await initialize();

    bool granted = true;
    if (!kIsWeb) {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final mac = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();

      final androidGranted = await android?.requestNotificationsPermission();
      final iosGranted = await ios?.requestPermissions(alert: true, badge: true, sound: true);
      final macGranted = await mac?.requestPermissions(alert: true, badge: true, sound: true);

      granted = (androidGranted ?? true) && (iosGranted ?? true) && (macGranted ?? true);
    }
    return granted;
  }

  Future<ReminderSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final rawSlotTimes = prefs.getString(_slotTimesKey);
    return ReminderSettings(
      enabled: prefs.getBool(_enabledKey) ?? true,
      slotTimes: rawSlotTimes == null
          ? const {}
          : (jsonDecode(rawSlotTimes) as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, value as int),
            ),
    );
  }

  Future<void> saveSettings(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setString(_slotTimesKey, jsonEncode(settings.slotTimes));
  }

  Future<void> cancelMedicationReminders() async {
    for (var i = 0; i < _notificationMaxCount; i++) {
      await _plugin.cancel(_notificationBaseId + i);
    }
  }

  Future<void> syncMedicationReminders({
    required ReminderSettings settings,
    required List<String> slotKeys,
    required bool isKorean,
  }) async {
    await initialize();
    await cancelMedicationReminders();

    if (!settings.enabled) return;

    final granted = await requestPermissions();
    if (!granted) return;

    final title = isKorean ? '복약 시간입니다' : 'Time to take your medication';
    final body = isKorean
        ? '앱을 닫아도 계속 알려드릴게요. 복용 후 체크해보세요.'
        : 'You will keep getting reminders even when the app is closed. Take your dose and check it off.';

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'pill_reminder_channel',
        'Pill Reminder',
        channelDescription: 'Scheduled medication reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    var id = _notificationBaseId;
    final now = tz.TZDateTime.now(tz.local);

    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final baseDate = now.add(Duration(days: dayOffset));
      for (var doseIndex = 0; doseIndex < slotKeys.length; doseIndex++) {
        final minutes = settings.slotTimes[slotKeys[doseIndex]] ??
            defaultReminderMinutes(slotKeys[doseIndex], doseIndex);
        final hour = minutes ~/ 60;
        final minute = minutes % 60;
        final scheduled = tz.TZDateTime(
          tz.local,
          baseDate.year,
          baseDate.month,
          baseDate.day,
          hour,
          minute,
        );
        if (!scheduled.isAfter(now)) {
          continue;
        }
        if (id >= _notificationBaseId + _notificationMaxCount) {
          return;
        }
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
        id += 1;
      }
    }
  }

  int defaultReminderMinutes(String slotKey, int slotIndex) {
    switch (slotKey) {
      case 'morning':
        return 8 * 60;
      case 'lunch':
        return 13 * 60;
      case 'evening':
        return 20 * 60;
      default:
        final fallback = 8 * 60 + (slotIndex * 180);
        return fallback.clamp(0, (23 * 60) + 59);
    }
  }
}

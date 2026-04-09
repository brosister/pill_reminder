import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderSettings {
  const ReminderSettings({
    required this.enabled,
    required this.intervalHours,
    required this.startHour,
    required this.endHour,
  });

  final bool enabled;
  final int intervalHours;
  final int startHour;
  final int endHour;

  ReminderSettings copyWith({
    bool? enabled,
    int? intervalHours,
    int? startHour,
    int? endHour,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      intervalHours: intervalHours ?? this.intervalHours,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
    );
  }
}

class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  static const _enabledKey = 'pill_reminder_enabled';
  static const _intervalKey = 'pill_reminder_interval_hours';
  static const _startHourKey = 'pill_reminder_start_hour';
  static const _endHourKey = 'pill_reminder_end_hour';
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
    return ReminderSettings(
      enabled: prefs.getBool(_enabledKey) ?? true,
      intervalHours: prefs.getInt(_intervalKey) ?? 8,
      startHour: prefs.getInt(_startHourKey) ?? 8,
      endHour: prefs.getInt(_endHourKey) ?? 20,
    );
  }

  Future<void> saveSettings(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setInt(_intervalKey, settings.intervalHours);
    await prefs.setInt(_startHourKey, settings.startHour);
    await prefs.setInt(_endHourKey, settings.endHour);
  }

  Future<void> cancelMedicationReminders() async {
    for (var i = 0; i < _notificationMaxCount; i++) {
      await _plugin.cancel(_notificationBaseId + i);
    }
  }

  Future<void> syncMedicationReminders({
    required ReminderSettings settings,
    required int dailyDoses,
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
      for (var doseIndex = 0; doseIndex < dailyDoses; doseIndex++) {
        final hour = settings.startHour + (doseIndex * settings.intervalHours);
        if (hour > settings.endHour || hour > 23) {
          continue;
        }
        final scheduled = tz.TZDateTime(
          tz.local,
          baseDate.year,
          baseDate.month,
          baseDate.day,
          hour,
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
}

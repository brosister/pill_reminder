import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MedicationLogEntry {
  const MedicationLogEntry({
    required this.title,
    required this.time,
    required this.skipped,
    required this.medicationNames,
    required this.dateKey,
  });

  final String title;
  final String time;
  final bool skipped;
  final List<String> medicationNames;
  final String dateKey;

  Map<String, dynamic> toJson() => {
        'title': title,
        'time': time,
        'skipped': skipped,
        'medicationNames': medicationNames,
        'dateKey': dateKey,
      };

  factory MedicationLogEntry.fromJson(Map<String, dynamic> json) => MedicationLogEntry(
        title: json['title'] as String? ?? '',
        time: json['time'] as String? ?? '',
        skipped: json['skipped'] as bool? ?? false,
        medicationNames: ((json['medicationNames'] as List?) ?? const []).map((e) => e.toString()).toList(),
        dateKey: json['dateKey'] as String? ?? '',
      );
}

class MedicationSnapshot {
  const MedicationSnapshot({
    required this.dateKey,
    required this.takenDoses,
    required this.dailyDoseGoal,
    required this.intervalHours,
    required this.startHour,
    required this.selectedPlan,
    required this.medicationNames,
    required this.logs,
  });

  final String dateKey;
  final int takenDoses;
  final int dailyDoseGoal;
  final int intervalHours;
  final int startHour;
  final int selectedPlan;
  final List<String> medicationNames;
  final List<MedicationLogEntry> logs;
}

class MedicationLogService {
  MedicationLogService._();
  static final MedicationLogService instance = MedicationLogService._();

  static const _dateKeyStorage = 'pill_reminder_current_date';
  static const _takenDosesKey = 'pill_reminder_taken_doses';
  static const _dailyDoseGoalKey = 'pill_reminder_daily_goal';
  static const _intervalKey = 'pill_reminder_interval_hours_local';
  static const _startHourKey = 'pill_reminder_start_hour_local';
  static const _selectedPlanKey = 'pill_reminder_selected_plan';
  static const _medicationNamesKey = 'pill_reminder_medication_names';
  static const _logsKey = 'pill_reminder_logs';

  String todayKey([DateTime? now]) {
    final date = now ?? DateTime.now();
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<MedicationSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final currentDate = todayKey();
    final savedDate = prefs.getString(_dateKeyStorage);

    if (savedDate != currentDate) {
      await prefs.setString(_dateKeyStorage, currentDate);
      await prefs.setInt(_takenDosesKey, 0);
      await prefs.setString(_logsKey, jsonEncode(<Map<String, dynamic>>[]));
    }

    final rawLogs = prefs.getString(_logsKey);
    final decodedLogs = rawLogs == null
        ? <MedicationLogEntry>[]
        : (jsonDecode(rawLogs) as List)
            .map((e) => MedicationLogEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((entry) => entry.dateKey == currentDate)
            .toList();

    return MedicationSnapshot(
      dateKey: currentDate,
      takenDoses: prefs.getInt(_takenDosesKey) ?? 0,
      dailyDoseGoal: prefs.getInt(_dailyDoseGoalKey) ?? 3,
      intervalHours: prefs.getInt(_intervalKey) ?? 8,
      startHour: prefs.getInt(_startHourKey) ?? 8,
      selectedPlan: prefs.getInt(_selectedPlanKey) ?? 1,
      medicationNames: prefs.getStringList(_medicationNamesKey) ?? const ['비타민', '영양제'],
      logs: decodedLogs,
    );
  }

  Future<void> saveState({
    required int takenDoses,
    required int dailyDoseGoal,
    required int intervalHours,
    required int startHour,
    required int selectedPlan,
    required List<String> medicationNames,
    required List<MedicationLogEntry> logs,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateKeyStorage, todayKey());
    await prefs.setInt(_takenDosesKey, takenDoses);
    await prefs.setInt(_dailyDoseGoalKey, dailyDoseGoal);
    await prefs.setInt(_intervalKey, intervalHours);
    await prefs.setInt(_startHourKey, startHour);
    await prefs.setInt(_selectedPlanKey, selectedPlan);
    await prefs.setStringList(_medicationNamesKey, medicationNames);
    await prefs.setString(_logsKey, jsonEncode(logs.map((e) => e.toJson()).toList()));
  }
}

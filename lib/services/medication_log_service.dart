import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MedicationItemState {
  const MedicationItemState({
    required this.name,
    required this.takenToday,
    required this.skippedToday,
  });

  final String name;
  final bool takenToday;
  final bool skippedToday;

  MedicationItemState copyWith({
    String? name,
    bool? takenToday,
    bool? skippedToday,
  }) {
    return MedicationItemState(
      name: name ?? this.name,
      takenToday: takenToday ?? this.takenToday,
      skippedToday: skippedToday ?? this.skippedToday,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'takenToday': takenToday,
        'skippedToday': skippedToday,
      };

  factory MedicationItemState.fromJson(Map<String, dynamic> json) => MedicationItemState(
        name: json['name'] as String? ?? '',
        takenToday: json['takenToday'] as bool? ?? false,
        skippedToday: json['skippedToday'] as bool? ?? false,
      );
}

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

class DailyMedicationSummary {
  const DailyMedicationSummary({
    required this.dateKey,
    required this.takenCount,
    required this.skippedCount,
    required this.goalCount,
  });

  final String dateKey;
  final int takenCount;
  final int skippedCount;
  final int goalCount;

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'takenCount': takenCount,
        'skippedCount': skippedCount,
        'goalCount': goalCount,
      };

  factory DailyMedicationSummary.fromJson(Map<String, dynamic> json) => DailyMedicationSummary(
        dateKey: json['dateKey'] as String? ?? '',
        takenCount: json['takenCount'] as int? ?? 0,
        skippedCount: json['skippedCount'] as int? ?? 0,
        goalCount: json['goalCount'] as int? ?? 0,
      );
}

class MedicationSnapshot {
  const MedicationSnapshot({
    required this.dateKey,
    required this.takenDoses,
    required this.cycleStatuses,
    required this.dailyDoseGoal,
    required this.intervalHours,
    required this.startHour,
    required this.doseMoments,
    required this.selectedPlan,
    required this.medications,
    required this.logs,
    required this.history,
  });

  final String dateKey;
  final int takenDoses;
  final List<String> cycleStatuses;
  final int dailyDoseGoal;
  final int intervalHours;
  final int startHour;
  final List<String> doseMoments;
  final int selectedPlan;
  final List<MedicationItemState> medications;
  final List<MedicationLogEntry> logs;
  final List<DailyMedicationSummary> history;
}

class MedicationLogService {
  MedicationLogService._();
  static final MedicationLogService instance = MedicationLogService._();

  static const _dateKeyStorage = 'pill_reminder_current_date';
  static const _takenDosesKey = 'pill_reminder_taken_doses';
  static const _cycleStatusesKey = 'pill_reminder_cycle_statuses';
  static const _dailyDoseGoalKey = 'pill_reminder_daily_goal';
  static const _intervalKey = 'pill_reminder_interval_hours_local';
  static const _startHourKey = 'pill_reminder_start_hour_local';
  static const _doseMomentsKey = 'pill_reminder_dose_moments';
  static const _selectedPlanKey = 'pill_reminder_selected_plan';
  static const _medicationNamesKey = 'pill_reminder_medications';
  static const _logsKey = 'pill_reminder_logs';
  static const _historyKey = 'pill_reminder_history';
  static const _weekStartKey = 'pill_reminder_week_start';
  static const _emptyMedicationWarningDismissedKey =
      'pill_reminder_empty_medication_warning_dismissed';
  static const _maxStoredLogs = 120;

  String todayKey([DateTime? now]) {
    final date = now ?? DateTime.now();
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime weekStart([DateTime? now]) {
    final date = now ?? DateTime.now();
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  String weekStartKey([DateTime? now]) => todayKey(weekStart(now));

  List<String> defaultDoseMoments(int dailyDoseGoal) {
    switch (dailyDoseGoal) {
      case 1:
        return ['lunch'];
      case 2:
        return ['morning', 'evening'];
      case 3:
        return ['morning', 'lunch', 'evening'];
      default:
        return List.generate(dailyDoseGoal, (index) => 'dose_${index + 1}');
    }
  }

  Future<void> _rolloverIfNeeded(SharedPreferences prefs) async {
    final currentDate = todayKey();
    final currentWeekStart = weekStartKey();
    final savedDate = prefs.getString(_dateKeyStorage);
    final savedWeekStart = prefs.getString(_weekStartKey);
    if (savedDate == null || savedDate == currentDate) {
      await prefs.setString(_dateKeyStorage, currentDate);
      await prefs.setString(_weekStartKey, currentWeekStart);
      if (savedWeekStart != null && savedWeekStart != currentWeekStart) {
        await prefs.setString(_historyKey, jsonEncode(<Map<String, dynamic>>[]));
      }
      return;
    }

    final taken = prefs.getInt(_takenDosesKey) ?? 0;
    final goal = prefs.getInt(_dailyDoseGoalKey) ?? 0;
    final rawCycleStatuses = prefs.getString(_cycleStatusesKey);
    final cycleStatuses = rawCycleStatuses == null
        ? const <String>[]
        : (jsonDecode(rawCycleStatuses) as List)
            .map((e) => e.toString())
            .toList();
    final medicationsRaw = prefs.getString(_medicationNamesKey);
    final medications = medicationsRaw == null
        ? <MedicationItemState>[]
        : (jsonDecode(medicationsRaw) as List)
            .map((e) => MedicationItemState.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
    final skippedCount =
        cycleStatuses.where((status) => status == 'skipped').length;

    final historyRaw = prefs.getString(_historyKey);
    var history = historyRaw == null
        ? <DailyMedicationSummary>[]
        : (jsonDecode(historyRaw) as List)
            .map((e) => DailyMedicationSummary.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

    if (savedWeekStart != null && savedWeekStart != currentWeekStart) {
      history = <DailyMedicationSummary>[];
    }

    history.insert(
      0,
      DailyMedicationSummary(
        dateKey: savedDate,
        takenCount: taken,
        skippedCount: skippedCount,
        goalCount: goal,
      ),
    );

    final trimmedHistory = history
        .where((item) => !_isBeforeWeek(item.dateKey, currentWeekStart))
        .take(7)
        .toList();
    final resetMeds = medications.map((m) => m.copyWith(takenToday: false, skippedToday: false)).toList();

    await prefs.setString(_historyKey, jsonEncode(trimmedHistory.map((e) => e.toJson()).toList()));
    await prefs.setString(_dateKeyStorage, currentDate);
    await prefs.setString(_weekStartKey, currentWeekStart);
    await prefs.setInt(_takenDosesKey, 0);
    await prefs.setString(_cycleStatusesKey, jsonEncode(<String>[]));
    await prefs.setString(_medicationNamesKey, jsonEncode(resetMeds.map((e) => e.toJson()).toList()));
  }

  bool _isBeforeWeek(String dateKeyValue, String weekStartKeyValue) {
    final date = DateTime.tryParse(dateKeyValue);
    final weekStartDate = DateTime.tryParse(weekStartKeyValue);
    if (date == null || weekStartDate == null) return false;
    return date.isBefore(weekStartDate);
  }

  Future<MedicationSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    await _rolloverIfNeeded(prefs);
    final currentDate = todayKey();

    final rawLogs = prefs.getString(_logsKey);
    final decodedLogs = rawLogs == null
        ? <MedicationLogEntry>[]
        : (jsonDecode(rawLogs) as List)
            .map((e) => MedicationLogEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .take(_maxStoredLogs)
            .toList();

    final medsRaw = prefs.getString(_medicationNamesKey);
    final medications = medsRaw == null
        ? const <MedicationItemState>[]
        : (jsonDecode(medsRaw) as List)
            .map((e) => MedicationItemState.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
    final rawCycleStatuses = prefs.getString(_cycleStatusesKey);
    final rawDoseMoments = prefs.getString(_doseMomentsKey);

    final currentWeekStart = weekStartKey();
    final historyRaw = prefs.getString(_historyKey);
    final history = historyRaw == null
        ? <DailyMedicationSummary>[]
        : (jsonDecode(historyRaw) as List)
            .map((e) => DailyMedicationSummary.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((entry) => !_isBeforeWeek(entry.dateKey, currentWeekStart))
            .toList();

    return MedicationSnapshot(
      dateKey: currentDate,
      takenDoses: prefs.getInt(_takenDosesKey) ?? 0,
      cycleStatuses: rawCycleStatuses == null
          ? const <String>[]
          : (jsonDecode(rawCycleStatuses) as List)
              .map((e) => e.toString())
              .toList(),
      dailyDoseGoal: prefs.getInt(_dailyDoseGoalKey) ?? 3,
      intervalHours: prefs.getInt(_intervalKey) ?? 8,
      startHour: prefs.getInt(_startHourKey) ?? 8,
      doseMoments: rawDoseMoments == null
          ? defaultDoseMoments(prefs.getInt(_dailyDoseGoalKey) ?? 3)
          : (jsonDecode(rawDoseMoments) as List)
              .map((e) => e.toString())
              .toList(),
      selectedPlan: prefs.getInt(_selectedPlanKey) ?? 1,
      medications: medications,
      logs: decodedLogs,
      history: history,
    );
  }

  Future<void> saveState({
    required int takenDoses,
    required List<String> cycleStatuses,
    required int dailyDoseGoal,
    required int intervalHours,
    required int startHour,
    required List<String> doseMoments,
    required int selectedPlan,
    required List<MedicationItemState> medications,
    required List<MedicationLogEntry> logs,
    required List<DailyMedicationSummary> history,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateKeyStorage, todayKey());
    await prefs.setString(_weekStartKey, weekStartKey());
    await prefs.setInt(_takenDosesKey, takenDoses);
    await prefs.setString(_cycleStatusesKey, jsonEncode(cycleStatuses));
    await prefs.setInt(_dailyDoseGoalKey, dailyDoseGoal);
    await prefs.setInt(_intervalKey, intervalHours);
    await prefs.setInt(_startHourKey, startHour);
    await prefs.setString(_doseMomentsKey, jsonEncode(doseMoments));
    await prefs.setInt(_selectedPlanKey, selectedPlan);
    await prefs.setString(_medicationNamesKey, jsonEncode(medications.map((e) => e.toJson()).toList()));
    await prefs.setString(
      _logsKey,
      jsonEncode(logs.take(_maxStoredLogs).map((e) => e.toJson()).toList()),
    );
    await prefs.setString(_historyKey, jsonEncode(history.map((e) => e.toJson()).toList()));
  }

  Future<bool> loadEmptyMedicationWarningDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_emptyMedicationWarningDismissedKey) ?? false;
  }

  Future<void> saveEmptyMedicationWarningDismissed(bool dismissed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emptyMedicationWarningDismissedKey, dismissed);
  }
}

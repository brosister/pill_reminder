import 'package:flutter/material.dart';

class PillPlan {
  const PillPlan({
    required this.label,
    required this.dailyDoses,
    required this.intervalHours,
    required this.startHour,
    required this.icon,
  });

  final String label;
  final int dailyDoses;
  final int intervalHours;
  final int startHour;
  final IconData icon;
}

class DoseLog {
  const DoseLog({
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
}

class DailyPillCount {
  const DailyPillCount({
    required this.day,
    required this.takenCount,
    required this.goalCount,
  });

  final DateTime day;
  final int takenCount;
  final int goalCount;
}

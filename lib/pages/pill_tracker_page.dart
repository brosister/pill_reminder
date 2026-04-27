import 'package:flutter/material.dart';

import '../models/app_copy.dart';
import '../services/medication_log_service.dart';
import '../services/toast_service.dart';
import '../widgets/pill_tracker_widgets.dart';

class PillTrackerPage extends StatelessWidget {
  const PillTrackerPage({
    super.key,
    required this.copy,
    required this.dailyDoseGoal,
    required this.cycleStatuses,
    required this.sevenDaySummaries,
    required this.onDoseChanged,
    required this.onMarkTaken,
    required this.onMarkSkipped,
    required this.bottomPadding,
  });

  final AppCopy copy;
  final int dailyDoseGoal;
  final List<String> cycleStatuses;
  final List<DailyMedicationSummary> sevenDaySummaries;
  final Future<void> Function(int value) onDoseChanged;
  final Future<void> Function() onMarkTaken;
  final Future<void> Function() onMarkSkipped;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final todayKey = MedicationLogService.instance.todayKey();
    final now = DateTime.now();
    final start = MedicationLogService.instance.weekStart(now);
    final summaryByDate = {
      for (final summary in sevenDaySummaries) summary.dateKey: summary,
    };
    final days = List.generate(7, (index) {
      final date = start.add(Duration(days: index));
      final key = MedicationLogService.instance.todayKey(date);
      final summary = summaryByDate[key];
      return PillTrackerDay(
        date: date,
        isToday: key == todayKey,
        taken: summary?.takenCount ?? 0,
        skipped: summary?.skippedCount ?? 0,
        goal: summary?.goalCount ?? dailyDoseGoal,
      );
    });

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 16, 18, bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.fullDate(now),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6A5D86),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 14),
            _DoseStepper(
              copy: copy,
              value: dailyDoseGoal,
              min: 1,
              max: 6,
              onChanged: onDoseChanged,
            ),
            const SizedBox(height: 18),
            Expanded(
              child: PillWeeklyTrackerGrid(
                copy: copy,
                days: days,
                columns: dailyDoseGoal,
                todayStatuses: cycleStatuses,
                onTapNext: onMarkTaken,
                onLongPressNext: onMarkSkipped,
                onTapUnavailable: () => ToastService.show(
                  copy.todayOnlyMessage(now),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoseStepper extends StatelessWidget {
  const _DoseStepper({
    required this.copy,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final AppCopy copy;
  final int value;
  final int min;
  final int max;
  final Future<void> Function(int value) onChanged;

  @override
  Widget build(BuildContext context) {
    final canDecrease = value > min;
    final canIncrease = value < max;

    return Row(
      children: [
        Text(
          copy.perDay,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF25164D),
              ),
        ),
        const SizedBox(width: 12),
        _CircleIconButton(
          icon: Icons.remove,
          enabled: canDecrease,
          onPressed: () => onChanged(value - 1),
        ),
        const SizedBox(width: 10),
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF25164D),
              ),
        ),
        const SizedBox(width: 10),
        _CircleIconButton(
          icon: Icons.add,
          enabled: canIncrease,
          onPressed: () => onChanged(value + 1),
        ),
        const SizedBox(width: 10),
        Text(
          copy.doseUnit,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF25164D),
              ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? const Color(0xFF25164D) : const Color(0xFFB4ABC7);
    return InkResponse(
      onTap: enabled ? onPressed : null,
      radius: 20,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withAlpha(115)),
          color: Colors.white.withAlpha(enabled ? 179 : 89),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

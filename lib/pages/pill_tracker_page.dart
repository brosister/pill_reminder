import 'package:flutter/material.dart';

import '../models/app_copy.dart';
import '../services/medication_log_service.dart';
import '../services/toast_service.dart';
import '../widgets/pill_tracker_widgets.dart';

class PillTrackerPage extends StatefulWidget {
  const PillTrackerPage({
    super.key,
    required this.copy,
    required this.dailyDoseGoal,
    required this.doseMoments,
    required this.cycleStatuses,
    required this.sevenDaySummaries,
    required this.onDoseChanged,
    required this.onDoseMomentsChanged,
    required this.onMarkTaken,
    required this.onMarkSkipped,
    required this.onOpenHistory,
    required this.onOpenSettings,
    required this.bottomPadding,
  });

  final AppCopy copy;
  final int dailyDoseGoal;
  final List<String> doseMoments;
  final List<String> cycleStatuses;
  final List<DailyMedicationSummary> sevenDaySummaries;
  final Future<void> Function(int value) onDoseChanged;
  final Future<void> Function(List<String> value) onDoseMomentsChanged;
  final Future<void> Function(int slotIndex) onMarkTaken;
  final Future<void> Function(int slotIndex) onMarkSkipped;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenSettings;
  final double bottomPadding;

  @override
  State<PillTrackerPage> createState() => _PillTrackerPageState();
}

class _PillTrackerPageState extends State<PillTrackerPage> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayKey = MedicationLogService.instance.todayKey(now);
    final displayedWeekStart = MedicationLogService.instance.weekStart(now);
    final summaryByDate = {
      for (final summary in widget.sevenDaySummaries) summary.dateKey: summary,
    };
    final days = List.generate(7, (index) {
      final date = displayedWeekStart.add(Duration(days: index));
      final key = MedicationLogService.instance.todayKey(date);
      final summary = summaryByDate[key];
      return PillTrackerDay(
        date: date,
        isToday: key == todayKey,
        taken: summary?.takenCount ?? 0,
        skipped: summary?.skippedCount ?? 0,
        goal: widget.dailyDoseGoal,
      );
    });

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(24, 12, 24, widget.bottomPadding + 18),
        children: [
          _DoseStepper(
            copy: widget.copy,
            value: widget.dailyDoseGoal,
            doseMoments: widget.doseMoments,
            min: 1,
            max: 6,
            onChanged: widget.onDoseChanged,
            onDoseMomentsChanged: widget.onDoseMomentsChanged,
          ),
          const SizedBox(height: 16),
          PillWeeklyTrackerGrid(
            copy: widget.copy,
            days: days,
            columns: widget.dailyDoseGoal,
            doseMoments: widget.doseMoments,
            todayStatuses: widget.cycleStatuses,
            onTapNext: widget.onMarkTaken,
            onLongPressNext: widget.onMarkSkipped,
            onTapUnavailable: () =>
                ToastService.show(widget.copy.todayOnlyMessage(now)),
          ),
          const SizedBox(height: 22),
          _ReminderCard(
            copy: widget.copy,
            onTap: widget.onOpenSettings,
          ),
        ],
      ),
    );
  }
}

class _DoseStepper extends StatelessWidget {
  const _DoseStepper({
    required this.copy,
    required this.value,
    required this.doseMoments,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onDoseMomentsChanged,
  });

  final AppCopy copy;
  final int value;
  final List<String> doseMoments;
  final int min;
  final int max;
  final Future<void> Function(int value) onChanged;
  final Future<void> Function(List<String> value) onDoseMomentsChanged;

  @override
  Widget build(BuildContext context) {
    final canDecrease = value > min;
    final canIncrease = value < max;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              copy.perDay,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF352391),
              ),
            ),
            const SizedBox(width: 8),
            _CircleIconButton(
              icon: Icons.remove,
              enabled: canDecrease,
              onPressed: () => onChanged(value - 1),
            ),
            const SizedBox(width: 10),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF352391),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              copy.doseUnit,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF352391),
              ),
            ),
            const SizedBox(width: 8),
            _CircleIconButton(
              icon: Icons.add,
              enabled: canIncrease,
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (value <= 3)
          _DoseMomentCheckboxRow(
            copy: copy,
            goal: value,
            doseMoments: doseMoments,
            onChanged: onDoseMomentsChanged,
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}
class _DoseMomentCheckboxRow extends StatelessWidget {
  const _DoseMomentCheckboxRow({
    required this.copy,
    required this.goal,
    required this.doseMoments,
    required this.onChanged,
  });

  final AppCopy copy;
  final int goal;
  final List<String> doseMoments;
  final Future<void> Function(List<String>) onChanged;

  static const _options = ['morning', 'lunch', 'evening'];

  @override
  Widget build(BuildContext context) {
    final selected = List<String>.from(doseMoments);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: _options.map((moment) {
        final checked = selected.contains(moment);
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(_toggleMoment(selected, moment, goal)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: checked,
                  onChanged: (_) => onChanged(_toggleMoment(selected, moment, goal)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _momentLabel(copy, moment),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6C6896),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<String> _toggleMoment(List<String> selected, String moment, int goal) {
    final next = List<String>.from(selected);
    if (next.contains(moment)) {
      next.remove(moment);
      return _orderedMoments(next);
    }
    if (next.length >= goal) {
      next.removeAt(0);
    }
    next.add(moment);
    return _orderedMoments(next);
  }

  List<String> _orderedMoments(List<String> values) {
    return _options.where(values.contains).toList();
  }
}

String _momentLabel(AppCopy copy, String moment) {
  switch (moment) {
    case 'morning':
      return copy.morningLabel;
    case 'lunch':
      return copy.lunchLabel;
    case 'evening':
      return copy.eveningLabel;
    default:
      return moment;
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
    final color = enabled ? const Color(0xFF5646BC) : const Color(0xFFC6BFF1);
    return InkResponse(
      onTap: enabled ? onPressed : null,
      radius: 22,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFDCCFFD)),
          color: Colors.white.withAlpha(220),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12A594E8),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 21, color: color),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.copy,
    required this.onTap,
  });

  final AppCopy copy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(220),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10A594E8),
                blurRadius: 32,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1ECFF),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  Icons.notifications_rounded,
                  color: Color(0xFF6A59ED),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copy.reminderCardTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2E2274),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      copy.reminderCardBody,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7772A6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                copy.reminderSettingsCta,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5B5890),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF5B5890),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

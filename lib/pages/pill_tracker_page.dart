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
    required this.cycleStatuses,
    required this.sevenDaySummaries,
    required this.onDoseChanged,
    required this.onMarkTaken,
    required this.onMarkSkipped,
    required this.onOpenHistory,
    required this.onOpenSettings,
    required this.bottomPadding,
  });

  final AppCopy copy;
  final int dailyDoseGoal;
  final List<String> cycleStatuses;
  final List<DailyMedicationSummary> sevenDaySummaries;
  final Future<void> Function(int value) onDoseChanged;
  final Future<void> Function(int slotIndex) onMarkTaken;
  final Future<void> Function(int slotIndex) onMarkSkipped;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenSettings;
  final double bottomPadding;

  @override
  State<PillTrackerPage> createState() => _PillTrackerPageState();
}

class _PillTrackerPageState extends State<PillTrackerPage> {
  int _weekOffset = 0;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayKey = MedicationLogService.instance.todayKey(now);
    final displayedWeekStart = MedicationLogService.instance
        .weekStart(now)
        .add(Duration(days: _weekOffset * 7));
    final displayedToday = _weekOffset == 0 ? now : displayedWeekStart;
    final summaryByDate = {
      for (final summary in widget.sevenDaySummaries) summary.dateKey: summary,
    };
    final days = List.generate(7, (index) {
      final date = displayedWeekStart.add(Duration(days: index));
      final key = MedicationLogService.instance.todayKey(date);
      final summary = summaryByDate[key];
      return PillTrackerDay(
        date: date,
        isToday: key == todayKey && _weekOffset == 0,
        taken: summary?.takenCount ?? 0,
        skipped: summary?.skippedCount ?? 0,
        goal: widget.dailyDoseGoal,
      );
    });

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(24, 8, 24, widget.bottomPadding + 18),
        children: [
          _TrackerHeader(
            copy: widget.copy,
            date: displayedToday,
            onOpenHistory: widget.onOpenHistory,
            onOpenSettings: widget.onOpenSettings,
          ),
          const SizedBox(height: 12),
          _WeekNavigator(
            copy: widget.copy,
            weekOffset: _weekOffset,
            onPrevious: () => setState(() => _weekOffset -= 1),
            onNext: () => setState(() => _weekOffset += 1),
          ),
          const SizedBox(height: 10),
          _DoseStepper(
            copy: widget.copy,
            value: widget.dailyDoseGoal,
            min: 1,
            max: 6,
            onChanged: widget.onDoseChanged,
          ),
          const SizedBox(height: 16),
          PillWeeklyTrackerGrid(
            copy: widget.copy,
            days: days,
            columns: widget.dailyDoseGoal,
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

class _TrackerHeader extends StatelessWidget {
  const _TrackerHeader({
    required this.copy,
    required this.date,
    required this.onOpenHistory,
    required this.onOpenSettings,
  });

  final AppCopy copy;
  final DateTime date;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy.trackerTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF2E2274),
                      letterSpacing: -1.0,
                      fontSize: 24,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                copy.fullDate(date),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF5B5890),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            _HeaderActionButton(
              icon: Icons.history,
              onTap: onOpenHistory,
            ),
            const SizedBox(width: 8),
            _HeaderActionButton(
              icon: Icons.settings,
              onTap: onOpenSettings,
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(210),
          borderRadius: BorderRadius.circular(21),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0AA594E8),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF5B5890), size: 22),
      ),
    );
  }
}

class _WeekNavigator extends StatelessWidget {
  const _WeekNavigator({
    required this.copy,
    required this.weekOffset,
    required this.onPrevious,
    required this.onNext,
  });

  final AppCopy copy;
  final int weekOffset;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final label = weekOffset == 0
        ? copy.todayLabel
        : weekOffset < 0
            ? '${copy.todayLabel} - ${weekOffset.abs()}'
            : '${copy.todayLabel} + $weekOffset';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundGhostButton(
          icon: Icons.chevron_left_rounded,
          onTap: onPrevious,
        ),
        const SizedBox(width: 22),
        Text(
          label,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF352391),
                fontSize: 20,
              ),
        ),
        const SizedBox(width: 22),
        _RoundGhostButton(
          icon: Icons.chevron_right_rounded,
          onTap: onNext,
        ),
      ],
    );
  }
}

class _RoundGhostButton extends StatelessWidget {
  const _RoundGhostButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFF2EDFF),
          borderRadius: BorderRadius.circular(23),
        ),
        child: Icon(icon, color: const Color(0xFF5646BC), size: 24),
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

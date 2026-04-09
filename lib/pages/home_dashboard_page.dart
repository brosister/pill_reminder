import 'package:flutter/material.dart';

import '../models/app_copy.dart';
import '../models/pill_models.dart';
import '../services/medication_log_service.dart';
import '../widgets/pill_shared_widgets.dart';

class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({
    super.key,
    required this.copy,
    required this.plans,
    required this.selectedPlan,
    required this.selected,
    required this.takenDoses,
    required this.dailyDoseGoal,
    required this.progress,
    required this.nextReminder,
    required this.doseHours,
    required this.cycleStatuses,
    required this.medications,
    required this.bottomPadding,
    required this.onApplyPlan,
    required this.onMarkCycleTaken,
    required this.onMarkCycleSkipped,
    required this.onToggleMedication,
    required this.onCompleteSelectedMedications,
    required this.onCompleteCurrentCycle,
    required this.emptyMedicationWarningDismissed,
    required this.onDismissEmptyMedicationWarning,
  });

  final AppCopy copy;
  final List<PillPlan> plans;
  final int selectedPlan;
  final PillPlan selected;
  final int takenDoses;
  final int dailyDoseGoal;
  final double progress;
  final String nextReminder;
  final List<int> doseHours;
  final List<String> cycleStatuses;
  final List<MedicationItemState> medications;
  final double bottomPadding;
  final ValueChanged<int> onApplyPlan;
  final VoidCallback onMarkCycleTaken;
  final VoidCallback onMarkCycleSkipped;
  final Future<void> Function(MedicationItemState, bool) onToggleMedication;
  final Future<void> Function(List<String>) onCompleteSelectedMedications;
  final Future<void> Function() onCompleteCurrentCycle;
  final bool emptyMedicationWarningDismissed;
  final Future<void> Function() onDismissEmptyMedicationWarning;

  @override
  Widget build(BuildContext context) {
    final scheduleFinished = cycleStatuses.length >= dailyDoseGoal;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionIntro(
              description: copy.headerSummary,
              icon: Icons.medication_liquid_rounded,
            ),
            const SizedBox(height: 18),
            _CompactSummaryStrip(
              copy: copy,
              takenDoses: takenDoses,
              dailyDoseGoal: dailyDoseGoal,
              nextReminder: nextReminder,
              checkedCount: medications
                  .where((m) => m.takenToday || m.skippedToday)
                  .length,
            ),
            const SizedBox(height: 18),
            _HeroDoseCard(
              copy: copy,
              takenDoses: takenDoses,
              dailyDoseGoal: dailyDoseGoal,
              progress: progress,
              nextReminder: nextReminder,
            ),
            const SizedBox(height: 18),
            _ActionCard(
              copy: copy,
              medications: medications,
              scheduleFinished: scheduleFinished,
              onAddDose: onMarkCycleTaken,
              onSkipDose: onMarkCycleSkipped,
              onCompleteSelectedMedications: onCompleteSelectedMedications,
              onCompleteCurrentCycle: onCompleteCurrentCycle,
              emptyMedicationWarningDismissed: emptyMedicationWarningDismissed,
              onDismissEmptyMedicationWarning: onDismissEmptyMedicationWarning,
            ),
            const SizedBox(height: 18),
            _DoseTimelineCard(
              copy: copy,
              doseHours: doseHours,
              cycleStatuses: cycleStatuses,
            ),
            const SizedBox(height: 18),
            Text(
              copy.quickPlans,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF25164D),
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 154,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: plans.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = plans[index];
                  return _PlanCard(
                    label: copy.planName(item.label),
                    detail: copy.planDetail(
                      item.dailyDoses,
                      item.intervalHours,
                      item.startHour,
                    ),
                    icon: item.icon,
                    selected: index == selectedPlan,
                    onTap: () => onApplyPlan(index),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 340;
                final first = MiniStatCard(
                  title: copy.doseGoal,
                  value: copy.doses(dailyDoseGoal),
                  subtitle: copy.planName(selected.label),
                  color: const Color(0xFF7A5AF8),
                  icon: Icons.medication_rounded,
                );
                final second = MiniStatCard(
                  title: copy.reminderInterval,
                  value: copy.intervalLabel(selected.intervalHours),
                  subtitle: copy.hourLabel(selected.startHour),
                  color: const Color(0xFF5B3CD0),
                  icon: Icons.alarm_rounded,
                );
                if (compact) {
                  return Column(
                    children: [
                      first,
                      const SizedBox(height: 12),
                      second,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: first),
                    const SizedBox(width: 12),
                    Expanded(child: second),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroDoseCard extends StatelessWidget {
  const _HeroDoseCard({
    required this.copy,
    required this.takenDoses,
    required this.dailyDoseGoal,
    required this.progress,
    required this.nextReminder,
  });

  final AppCopy copy;
  final int takenDoses;
  final int dailyDoseGoal;
  final double progress;
  final String nextReminder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7A5AF8), Color(0xFFB18FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x337A5AF8),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(250, 250),
                  painter: PillRingPainter(progress: progress),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      copy.completionText(takenDoses, dailyDoseGoal),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      copy.rateText((progress * 100).round()),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${copy.nextReminder} · $nextReminder',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (takenDoses >= dailyDoseGoal)
            Text(
              copy.goalReached,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _CompactSummaryStrip extends StatelessWidget {
  const _CompactSummaryStrip({
    required this.copy,
    required this.takenDoses,
    required this.dailyDoseGoal,
    required this.nextReminder,
    required this.checkedCount,
  });

  final AppCopy copy;
  final int takenDoses;
  final int dailyDoseGoal;
  final String nextReminder;
  final int checkedCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final first = _CompactSummaryCard(
          title: copy.todaySummary,
          value: copy.completionText(takenDoses, dailyDoseGoal),
          subtitle: '',
          color: const Color(0xFF7A5AF8),
          icon: Icons.flag_rounded,
        );
        final second = _CompactSummaryCard(
          title: copy.nextReminder,
          value: nextReminder,
          subtitle: '',
          color: const Color(0xFFFF7A59),
          icon: Icons.schedule_rounded,
        );
        if (constraints.maxWidth < 360) {
          return Column(
            children: [
              first,
              const SizedBox(height: 12),
              second,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _CompactSummaryCard extends StatelessWidget {
  const _CompactSummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7B74A3),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF25164D),
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8A82AE),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoseTimelineCard extends StatelessWidget {
  const _DoseTimelineCard({
    required this.copy,
    required this.doseHours,
    required this.cycleStatuses,
  });

  final AppCopy copy;
  final List<int> doseHours;
  final List<String> cycleStatuses;

  @override
  Widget build(BuildContext context) {
    return CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.doseTimeline,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF25164D),
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(doseHours.length, (index) {
            final status = index < cycleStatuses.length
                ? cycleStatuses[index]
                : 'pending';
            final state = switch (status) {
              'taken' => copy.completedState,
              'skipped' => copy.skippedState,
              _ => copy.pendingState,
            };
            final dotColor = switch (status) {
              'taken' => const Color(0xFF7A5AF8),
              'skipped' => const Color(0xFFFF9A6B),
              _ => const Color(0xFFD7CCF7),
            };
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F2FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          copy.doseSlotLabel(index),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF25164D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          copy.hourLabel(doseHours[index]),
                          style: const TextStyle(color: Color(0xFF7B74A3)),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    state,
                    style: TextStyle(
                      color: switch (status) {
                        'taken' => const Color(0xFF5B3CD0),
                        'skipped' => const Color(0xFFE06A2C),
                        _ => const Color(0xFF9A8FC3),
                      },
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.copy,
    required this.medications,
    required this.scheduleFinished,
    required this.onAddDose,
    required this.onSkipDose,
    required this.onCompleteSelectedMedications,
    required this.onCompleteCurrentCycle,
    required this.emptyMedicationWarningDismissed,
    required this.onDismissEmptyMedicationWarning,
  });

  final AppCopy copy;
  final List<MedicationItemState> medications;
  final bool scheduleFinished;
  final VoidCallback onAddDose;
  final VoidCallback onSkipDose;
  final Future<void> Function(List<String>) onCompleteSelectedMedications;
  final Future<void> Function() onCompleteCurrentCycle;
  final bool emptyMedicationWarningDismissed;
  final Future<void> Function() onDismissEmptyMedicationWarning;

  @override
  Widget build(BuildContext context) {
    final primaryButtonStyle = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(60),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
    final secondaryButtonStyle = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(60),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );

    return CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            medications.isEmpty ? copy.cycleActionHint : copy.completeDoseHint,
            style: const TextStyle(
              color: Color(0xFF7B74A3),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: scheduleFinished
                  ? null
                  : () async {
                if (medications.isEmpty) {
                  if (!emptyMedicationWarningDismissed) {
                    final decision = await showDialog<_EmptyMedicationDecision>(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                copy.noMedicationWarningTitle,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF25164D),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                copy.noMedicationWarningBody,
                                style: const TextStyle(
                                  color: Color(0xFF6C6192),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize:
                                            const Size.fromHeight(52),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: Text(copy.cancel),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () => Navigator.of(context).pop(
                                        _EmptyMedicationDecision.proceed,
                                      ),
                                      style: FilledButton.styleFrom(
                                        minimumSize:
                                            const Size.fromHeight(52),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: Text(copy.proceedAnyway),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.tonal(
                                  onPressed: () => Navigator.of(context).pop(
                                    _EmptyMedicationDecision
                                        .proceedAndDontAskAgain,
                                  ),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                    backgroundColor:
                                        const Color(0xFFEDE7FF),
                                    foregroundColor:
                                        const Color(0xFF5B3CD0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(copy.dontAskAgain),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                    if (decision == null) return;
                    if (decision ==
                        _EmptyMedicationDecision.proceedAndDontAskAgain) {
                      await onDismissEmptyMedicationWarning();
                    }
                  }
                  onAddDose();
                  return;
                }
                final selected =
                    await showModalBottomSheet<_MedicationSheetResult>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => _MedicationCompleteSheet(
                    copy: copy,
                    medications: medications,
                    scheduleFinished: scheduleFinished,
                    onCompleteCurrentCycle: onCompleteCurrentCycle,
                  ),
                );
                if (selected case _MedicationSheetResult(
                  names: final names,
                  completeCurrentCycle: final completeCurrentCycle,
                )) {
                  if (names.isNotEmpty) {
                    await onCompleteSelectedMedications(names);
                  } else if (completeCurrentCycle) {
                    await onCompleteCurrentCycle();
                  }
                }
              },
              style: primaryButtonStyle,
              icon: const Icon(Icons.check_rounded),
              label: Text(
                medications.isEmpty ? copy.addDose : copy.takenLabel,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onSkipDose,
              style: secondaryButtonStyle,
              icon: const Icon(Icons.skip_next_rounded),
              label: Text(copy.skipDose),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationCompleteSheet extends StatefulWidget {
  const _MedicationCompleteSheet({
    required this.copy,
    required this.medications,
    required this.scheduleFinished,
    required this.onCompleteCurrentCycle,
  });

  final AppCopy copy;
  final List<MedicationItemState> medications;
  final bool scheduleFinished;
  final Future<void> Function() onCompleteCurrentCycle;

  @override
  State<_MedicationCompleteSheet> createState() =>
      _MedicationCompleteSheetState();
}

class _MedicationCompleteSheetState extends State<_MedicationCompleteSheet> {
  late final Set<String> _selectedNames;

  @override
  void initState() {
    super.initState();
    _selectedNames = widget.medications
        .where((medication) => medication.takenToday)
        .map((medication) => medication.name)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final copy = widget.copy;
    final medications = widget.medications;
    final lockedNames = medications
        .where((medication) => medication.takenToday)
        .map((medication) => medication.name)
        .toSet();
    final availableNames = medications
        .where((medication) => !medication.takenToday)
        .map((medication) => medication.name)
        .toList();
    final hasPartialCompleted = lockedNames.isNotEmpty && !widget.scheduleFinished;
    final allAvailableSelected = availableNames.isNotEmpty &&
        availableNames.every((name) => _selectedNames.contains(name));

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: CardShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy.completeSelectionTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF25164D),
                ),
              ),
              const SizedBox(height: 14),
              _SelectionTile(
                label: copy.completeAllOption,
                selected: medications.isNotEmpty &&
                    medications.every(
                      (medication) => _selectedNames.contains(medication.name),
                    ),
                onTap: availableNames.isEmpty
                    ? null
                    : () {
                  setState(() {
                    if (allAvailableSelected) {
                      _selectedNames.removeAll(availableNames);
                    } else {
                      _selectedNames.addAll(availableNames);
                    }
                  });
                },
              ),
              const SizedBox(height: 10),
              ...medications.map(
                (med) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SelectionTile(
                    label: med.name,
                    selected: _selectedNames.contains(med.name),
                    disabled: med.takenToday,
                    onTap: med.takenToday
                        ? null
                        : () {
                            setState(() {
                              if (_selectedNames.contains(med.name)) {
                                _selectedNames.remove(med.name);
                              } else {
                                _selectedNames.add(med.name);
                              }
                            });
                          },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedNames.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(
                            _MedicationSheetResult(
                              names: medications
                                  .where(
                                    (med) =>
                                        _selectedNames.contains(med.name) &&
                                        !med.takenToday,
                                  )
                                  .map((med) => med.name)
                                  .toList(),
                              completeCurrentCycle: false,
                            ),
                          ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(copy.completeSelectedButton),
                ),
              ),
              if (hasPartialCompleted) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(
                      const _MedicationSheetResult(
                        names: <String>[],
                        completeCurrentCycle: true,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(copy.completeCurrentCycleButton),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicationSheetResult {
  const _MedicationSheetResult({
    required this.names,
    required this.completeCurrentCycle,
  });

  final List<String> names;
  final bool completeCurrentCycle;
}

enum _EmptyMedicationDecision {
  proceed,
  proceedAndDontAskAgain,
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.disabled = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: disabled
              ? const Color(0xFFF1EDF8)
              : selected
                  ? const Color(0xFFEEE7FF)
                  : const Color(0xFFF7F2FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF7A5AF8) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: disabled
                      ? const Color(0xFF8F88B0)
                      : const Color(0xFF25164D),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF7A5AF8) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF7A5AF8)
                      : const Color(0xFFD7CCF7),
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.label,
    required this.detail,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String detail;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.sizeOf(context).width < 380 ? 152.0 : 168.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: cardWidth,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF25164D) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? const Color(0x2625164D)
                  : const Color(0x10000000),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? Colors.white : const Color(0xFF7A5AF8)),
            const SizedBox(height: 14),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF25164D),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white70 : const Color(0xFF6C6192),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

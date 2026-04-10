import 'package:flutter/material.dart';

import '../models/app_copy.dart';
import '../services/medication_log_service.dart';
import '../widgets/pill_shared_widgets.dart';

class PillSettingsPage extends StatefulWidget {
  const PillSettingsPage({
    super.key,
    required this.copy,
    required this.remindersEnabled,
    required this.intervalHours,
    required this.startHourValue,
    required this.dailyDoseGoal,
    required this.medications,
    required this.medicationController,
    required this.doseOptions,
    required this.intervalOptions,
    required this.startHourOptions,
    required this.onReminderChanged,
    required this.onDoseChanged,
    required this.onIntervalChanged,
    required this.onStartHourChanged,
    required this.onAddMedication,
    required this.onRemoveMedication,
    required this.onResetToday,
    required this.onSeedKoreanPreviewData,
    required this.onSeedEnglishPreviewData,
  });

  final AppCopy copy;
  final bool remindersEnabled;
  final int intervalHours;
  final int startHourValue;
  final int dailyDoseGoal;
  final List<MedicationItemState> medications;
  final TextEditingController medicationController;
  final List<int> doseOptions;
  final List<int> intervalOptions;
  final List<int> startHourOptions;
  final Future<bool> Function(bool) onReminderChanged;
  final Future<void> Function(int) onDoseChanged;
  final Future<void> Function(int) onIntervalChanged;
  final Future<void> Function(int) onStartHourChanged;
  final Future<void> Function() onAddMedication;
  final Future<void> Function(String) onRemoveMedication;
  final Future<void> Function() onResetToday;
  final Future<void> Function() onSeedKoreanPreviewData;
  final Future<void> Function() onSeedEnglishPreviewData;

  @override
  State<PillSettingsPage> createState() => _PillSettingsPageState();
}

class _PillSettingsPageState extends State<PillSettingsPage> {
  late bool _remindersEnabled;
  late int _intervalHours;
  late int _startHourValue;
  late int _dailyDoseGoal;

  @override
  void initState() {
    super.initState();
    _remindersEnabled = widget.remindersEnabled;
    _intervalHours = widget.intervalHours;
    _startHourValue = widget.startHourValue;
    _dailyDoseGoal = widget.dailyDoseGoal;
  }

  @override
  void didUpdateWidget(covariant PillSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.remindersEnabled != widget.remindersEnabled) {
      _remindersEnabled = widget.remindersEnabled;
    }
    if (oldWidget.intervalHours != widget.intervalHours) {
      _intervalHours = widget.intervalHours;
    }
    if (oldWidget.startHourValue != widget.startHourValue) {
      _startHourValue = widget.startHourValue;
    }
    if (oldWidget.dailyDoseGoal != widget.dailyDoseGoal) {
      _dailyDoseGoal = widget.dailyDoseGoal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomBannerPageScaffold(
      title: widget.copy.settingsTitle,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          kPageBottomContentPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MedicationManagerCard(
              copy: widget.copy,
              medications: widget.medications,
              controller: widget.medicationController,
              onAddMedication: () async {
                await widget.onAddMedication();
                if (!mounted) return;
                setState(() {});
              },
              onRemoveMedication: (name) async {
                await widget.onRemoveMedication(name);
                if (!mounted) return;
                setState(() {});
              },
            ),
            const SizedBox(height: 18),
            _ReminderStatusCard(
              copy: widget.copy,
              enabled: _remindersEnabled,
              intervalHours: _intervalHours,
              onChanged: (value) async {
                setState(() => _remindersEnabled = value);
                final actual = await widget.onReminderChanged(value);
                if (!mounted) return;
                setState(() => _remindersEnabled = actual);
              },
            ),
            const SizedBox(height: 18),
            _SettingsCard(
              copy: widget.copy,
              dailyDoseGoal: _dailyDoseGoal,
              intervalHours: _intervalHours,
              startHourValue: _startHourValue,
              doseOptions: widget.doseOptions,
              intervalOptions: widget.intervalOptions,
              startHourOptions: widget.startHourOptions,
              onDoseChanged: (value) async {
                setState(() => _dailyDoseGoal = value);
                await widget.onDoseChanged(value);
              },
              onIntervalChanged: (value) async {
                setState(() => _intervalHours = value);
                await widget.onIntervalChanged(value);
              },
              onStartHourChanged: (value) async {
                setState(() => _startHourValue = value);
                await widget.onStartHourChanged(value);
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(widget.copy.resetTodayConfirmTitle),
                      content: Text(widget.copy.resetTodayConfirmBody),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(widget.copy.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(widget.copy.confirm),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await widget.onResetToday();
                  }
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(widget.copy.resetToday),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await widget.onSeedKoreanPreviewData();
                  if (!mounted) return;
                  setState(() {});
                },
                icon: const Icon(Icons.history_edu_rounded),
                label: const Text('리셋 + 한글 테스트데이터 추가'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await widget.onSeedEnglishPreviewData();
                  if (!mounted) return;
                  setState(() {});
                },
                icon: const Icon(Icons.translate_rounded),
                label: const Text('리셋 + 영어 테스트데이터 추가'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderStatusCard extends StatelessWidget {
  const _ReminderStatusCard({
    required this.copy,
    required this.enabled,
    required this.intervalHours,
    required this.onChanged,
  });

  final AppCopy copy;
  final bool enabled;
  final int intervalHours;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF7A5AF8).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFF7A5AF8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copy.reminderStatus,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF25164D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      enabled ? copy.reminderOn : copy.reminderOff,
                      style: const TextStyle(
                        color: Color(0xFF6C6192),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: enabled, onChanged: onChanged),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            copy.intervalLabel(intervalHours),
            style: const TextStyle(
              color: Color(0xFF5B3CD0),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationManagerCard extends StatelessWidget {
  const _MedicationManagerCard({
    required this.copy,
    required this.medications,
    required this.controller,
    required this.onAddMedication,
    required this.onRemoveMedication,
  });

  final AppCopy copy;
  final List<MedicationItemState> medications;
  final TextEditingController controller;
  final Future<void> Function() onAddMedication;
  final Future<void> Function(String) onRemoveMedication;

  @override
  Widget build(BuildContext context) {
    return CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.medications,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF25164D),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            copy.isKorean
                ? '복용 중인 약만 직접 추가해서 체크 목록을 구성해 보세요.'
                : 'Add only the medicines you actually take to build your checklist.',
            style: const TextStyle(
              color: Color(0xFF6C6192),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 1,
                    decoration: InputDecoration(
                      hintText: copy.medicationHint,
                      filled: true,
                      fillColor: const Color(0xFFF7F2FF),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => onAddMedication(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: onAddMedication,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 56),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(copy.addMedication),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (medications.isEmpty)
            Text(
              copy.isKorean ? '아직 추가된 약이 없습니다.' : 'No medications added yet.',
              style: const TextStyle(color: Color(0xFF7B74A3)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: medications
                  .map(
                    (med) => Chip(
                      label: Text(med.name),
                      onDeleted: () => onRemoveMedication(med.name),
                      deleteIconColor: const Color(0xFF6C6192),
                      backgroundColor: const Color(0xFFF2ECFF),
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 8),
          Text(
            '${copy.medsCountSetting}: ${copy.countLabel(medications.length)}',
            style: const TextStyle(color: Color(0xFF7B74A3)),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.copy,
    required this.dailyDoseGoal,
    required this.intervalHours,
    required this.startHourValue,
    required this.doseOptions,
    required this.intervalOptions,
    required this.startHourOptions,
    required this.onDoseChanged,
    required this.onIntervalChanged,
    required this.onStartHourChanged,
  });

  final AppCopy copy;
  final int dailyDoseGoal;
  final int intervalHours;
  final int startHourValue;
  final List<int> doseOptions;
  final List<int> intervalOptions;
  final List<int> startHourOptions;
  final ValueChanged<int> onDoseChanged;
  final ValueChanged<int> onIntervalChanged;
  final ValueChanged<int> onStartHourChanged;

  @override
  Widget build(BuildContext context) {
    return CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.currentCycle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF25164D),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 500;
              final children = [
                _PickerTile(
                  label: copy.doseGoal,
                  value: dailyDoseGoal,
                  textForValue: copy.doses,
                  icon: Icons.medication_rounded,
                  onChanged: onDoseChanged,
                  values: doseOptions,
                ),
                _PickerTile(
                  label: copy.reminderInterval,
                  value: intervalHours,
                  textForValue: copy.intervalLabel,
                  icon: Icons.av_timer_rounded,
                  onChanged: onIntervalChanged,
                  values: intervalOptions,
                ),
                _PickerTile(
                  label: copy.startHour,
                  value: startHourValue,
                  textForValue: copy.hourLabel,
                  icon: Icons.access_time_rounded,
                  onChanged: onStartHourChanged,
                  values: startHourOptions,
                ),
              ];
              if (isCompact) {
                return Column(
                  children: [
                    for (var i = 0; i < children.length; i++) ...[
                      children[i],
                      if (i != children.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: children[0]),
                  const SizedBox(width: 12),
                  Expanded(child: children[1]),
                  const SizedBox(width: 12),
                  Expanded(child: children[2]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.value,
    required this.textForValue,
    required this.icon,
    required this.onChanged,
    required this.values,
  });

  final String label;
  final int value;
  final String Function(int) textForValue;
  final IconData icon;
  final ValueChanged<int> onChanged;
  final List<int> values;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF7A5AF8)),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF25164D),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: value,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            items: values
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text(textForValue(v)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

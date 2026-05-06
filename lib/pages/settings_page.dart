import 'package:flutter/material.dart';

import '../models/app_copy.dart';
import '../services/medication_log_service.dart';
import '../widgets/pill_shared_widgets.dart';

class PillSettingsPage extends StatefulWidget {
  const PillSettingsPage({
    super.key,
    required this.copy,
    required this.remindersEnabled,
    required this.dailyDoseGoal,
    required this.doseMoments,
    required this.reminderTimes,
    required this.medications,
    required this.medicationController,
    required this.onReminderChanged,
    required this.onReminderTimeChanged,
    required this.onAddMedication,
    required this.onRemoveMedication,
    required this.onResetToday,
  });

  final AppCopy copy;
  final bool remindersEnabled;
  final int dailyDoseGoal;
  final List<String> doseMoments;
  final Map<String, int> reminderTimes;
  final List<MedicationItemState> medications;
  final TextEditingController medicationController;
  final Future<bool> Function(bool) onReminderChanged;
  final Future<void> Function(String slotKey, int minutes)
      onReminderTimeChanged;
  final Future<void> Function() onAddMedication;
  final Future<void> Function(String) onRemoveMedication;
  final Future<void> Function() onResetToday;

  @override
  State<PillSettingsPage> createState() => _PillSettingsPageState();
}

class _PillSettingsPageState extends State<PillSettingsPage> {
  late bool _remindersEnabled;
  late Map<String, int> _reminderTimes;

  @override
  void initState() {
    super.initState();
    _remindersEnabled = widget.remindersEnabled;
    _reminderTimes = Map<String, int>.from(widget.reminderTimes);
  }

  @override
  void didUpdateWidget(covariant PillSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.remindersEnabled != widget.remindersEnabled) {
      _remindersEnabled = widget.remindersEnabled;
    }
    if (oldWidget.reminderTimes != widget.reminderTimes) {
      _reminderTimes = Map<String, int>.from(widget.reminderTimes);
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
              onChanged: (value) async {
                setState(() => _remindersEnabled = value);
                final actual = await widget.onReminderChanged(value);
                if (!mounted) return;
                setState(() => _remindersEnabled = actual);
              },
            ),
            const SizedBox(height: 18),
            _ReminderTimeCard(
              copy: widget.copy,
              slotKeys: _currentReminderSlots(),
              reminderTimes: _reminderTimes,
              onTapTime: (slotKey) async {
                final currentMinutes = _reminderTimes[slotKey] ??
                    _defaultReminderMinutes(slotKey, _currentReminderSlots().indexOf(slotKey));
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: currentMinutes ~/ 60,
                    minute: currentMinutes % 60,
                  ),
                );
                if (picked == null) return;
                final nextMinutes = (picked.hour * 60) + picked.minute;
                setState(() {
                  _reminderTimes = {
                    ..._reminderTimes,
                    slotKey: nextMinutes,
                  };
                });
                await widget.onReminderTimeChanged(slotKey, nextMinutes);
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
          ],
        ),
      ),
    );
  }
}

extension on _PillSettingsPageState {
  List<String> _currentReminderSlots() {
    if (widget.dailyDoseGoal >= 4) {
      return List.generate(widget.dailyDoseGoal, (index) => 'dose_${index + 1}');
    }
    if (widget.doseMoments.isEmpty) {
      return _defaultDoseMoments(widget.dailyDoseGoal).take(1).toList();
    }
    return List<String>.from(widget.doseMoments);
  }
}

List<String> _defaultDoseMoments(int dailyDoseGoal) {
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

int _defaultReminderMinutes(String slotKey, int slotIndex) {
  switch (slotKey) {
    case 'morning':
      return 8 * 60;
    case 'lunch':
      return 13 * 60;
    case 'evening':
      return 20 * 60;
    default:
      return (8 * 60) + (slotIndex * 180);
  }
}

class _ReminderStatusCard extends StatelessWidget {
  const _ReminderStatusCard({
    required this.copy,
    required this.enabled,
    required this.onChanged,
  });

  final AppCopy copy;
  final bool enabled;
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

class _ReminderTimeCard extends StatelessWidget {
  const _ReminderTimeCard({
    required this.copy,
    required this.slotKeys,
    required this.reminderTimes,
    required this.onTapTime,
  });

  final AppCopy copy;
  final List<String> slotKeys;
  final Map<String, int> reminderTimes;
  final ValueChanged<String> onTapTime;

  @override
  Widget build(BuildContext context) {
    return CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.reminderTimeSettings,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF25164D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            copy.reminderTimeSettingsHint,
            style: const TextStyle(
              color: Color(0xFF6C6192),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(slotKeys.length, (index) {
            final slotKey = slotKeys[index];
            final minutes = reminderTimes[slotKey] ??
                _defaultReminderMinutes(slotKey, index);
            return Padding(
              padding: EdgeInsets.only(bottom: index == slotKeys.length - 1 ? 0 : 12),
              child: _ReminderTimeTile(
                label: _slotLabel(copy, slotKey, index),
                timeLabel: _formatMinutes(copy, minutes),
                onTap: () => onTapTime(slotKey),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ReminderTimeTile extends StatelessWidget {
  const _ReminderTimeTile({
    required this.label,
    required this.timeLabel,
    required this.onTap,
  });

  final String label;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F2FF),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: Color(0xFF7A5AF8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF25164D),
                  ),
                ),
              ),
              Text(
                timeLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5B3CD0),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF5B5890),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _slotLabel(AppCopy copy, String slotKey, int slotIndex) {
  switch (slotKey) {
    case 'morning':
      return copy.morningLabel;
    case 'lunch':
      return copy.lunchLabel;
    case 'evening':
      return copy.eveningLabel;
    default:
      return copy.doseSlotLabel(slotIndex);
  }
}

String _formatMinutes(AppCopy copy, int minutes) {
  final hour = (minutes ~/ 60) % 24;
  final minute = minutes % 60;
  if (copy.isKorean) {
    final period = hour < 12 ? '오전' : '오후';
    final normalizedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$period $normalizedHour:${minute.toString().padLeft(2, '0')}';
  }
  final period = hour < 12 ? 'AM' : 'PM';
  final normalizedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$normalizedHour:${minute.toString().padLeft(2, '0')} $period';
}


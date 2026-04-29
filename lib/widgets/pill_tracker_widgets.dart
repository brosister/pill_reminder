import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_copy.dart';

class PillWeeklyTrackerGrid extends StatelessWidget {
  const PillWeeklyTrackerGrid({
    super.key,
    required this.copy,
    required this.days,
    required this.columns,
    required this.todayStatuses,
    required this.onTapNext,
    required this.onLongPressNext,
    required this.onTapUnavailable,
  });

  final AppCopy copy;
  final List<PillTrackerDay> days;
  final int columns;
  final List<String> todayStatuses;
  final Future<void> Function(int slotIndex) onTapNext;
  final Future<void> Function(int slotIndex) onLongPressNext;
  final Future<void> Function() onTapUnavailable;

  @override
  Widget build(BuildContext context) {
    final columnCount = math.max(1, columns);
    return Column(
      children: [
        _TrackerTableHeader(copy: copy, columnCount: columnCount),
        const SizedBox(height: 10),
        ...List.generate(days.length, (index) {
          final day = days[index];
          final statuses = day.isToday
              ? _buildTodayStatuses(todayStatuses, columnCount)
              : _buildHistoricalStatuses(
                  taken: day.taken,
                  skipped: day.skipped,
                  columns: columnCount,
                );
          return Padding(
            padding: EdgeInsets.only(bottom: index == days.length - 1 ? 0 : 10),
            child: _TrackerRowCard(
              copy: copy,
              day: day,
              statuses: statuses,
              todayStatuses: todayStatuses,
              onTapNext: onTapNext,
              onLongPressNext: onLongPressNext,
              onTapUnavailable: onTapUnavailable,
            ),
          );
        }),
      ],
    );
  }

  List<PillTrackerSlotStatus> _buildTodayStatuses(
    List<String> cycleStatuses,
    int columns,
  ) {
    return List.generate(columns, (index) {
      if (index >= cycleStatuses.length) return PillTrackerSlotStatus.pending;
      final value = cycleStatuses[index];
      if (value == 'skipped') return PillTrackerSlotStatus.skipped;
      if (value == 'taken') return PillTrackerSlotStatus.taken;
      return PillTrackerSlotStatus.pending;
    });
  }

  List<PillTrackerSlotStatus> _buildHistoricalStatuses({
    required int taken,
    required int skipped,
    required int columns,
  }) {
    final available = columns;
    final filledTaken = math.max(0, math.min(available, taken));
    final filledSkipped =
        math.max(0, math.min(available - filledTaken, skipped));

    return List.generate(columns, (index) {
      if (index < filledTaken) return PillTrackerSlotStatus.taken;
      if (index < filledTaken + filledSkipped) {
        return PillTrackerSlotStatus.skipped;
      }
      return PillTrackerSlotStatus.pending;
    });
  }
}

class _TrackerTableHeader extends StatelessWidget {
  const _TrackerTableHeader({
    required this.copy,
    required this.columnCount,
  });

  final AppCopy copy;
  final int columnCount;

  @override
  Widget build(BuildContext context) {
    final headers = _buildHeaders();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              copy.weekdayHeader,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8E89B1),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: List.generate(columnCount, (index) {
                final item = headers[index];
                return Expanded(
                  child: _ColumnHeader(
                    iconAsset: item.iconAsset,
                    label: item.label,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  List<_ColumnHeaderData> _buildHeaders() {
    switch (columnCount) {
      case 1:
        return [
          _ColumnHeaderData(
            iconAsset: 'assets/icons/sun.png',
            label: copy.morningLabel,
          ),
        ];
      case 2:
        return [
          _ColumnHeaderData(
            iconAsset: 'assets/icons/sun.png',
            label: copy.morningLabel,
          ),
          _ColumnHeaderData(
            iconAsset: 'assets/icons/moon.png',
            label: copy.eveningLabel,
          ),
        ];
      case 3:
        return [
          _ColumnHeaderData(
            iconAsset: 'assets/icons/sun.png',
            label: copy.morningLabel,
          ),
          _ColumnHeaderData(
            iconAsset: 'assets/icons/sun.png',
            label: copy.lunchLabel,
          ),
          _ColumnHeaderData(
            iconAsset: 'assets/icons/moon.png',
            label: copy.eveningLabel,
          ),
        ];
      default:
        return List.generate(columnCount, (index) {
          if (index == 0) {
            return _ColumnHeaderData(
              iconAsset: 'assets/icons/sun.png',
              label: copy.morningLabel,
            );
          }
          if (index == 1) {
            return _ColumnHeaderData(
              iconAsset: 'assets/icons/sun.png',
              label: copy.lunchLabel,
            );
          }
          return _ColumnHeaderData(
            iconAsset: 'assets/icons/moon.png',
            label: copy.eveningLabel,
          );
        });
    }
  }
}

class _ColumnHeaderData {
  const _ColumnHeaderData({
    required this.iconAsset,
    required this.label,
  });

  final String iconAsset;
  final String label;
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({
    required this.iconAsset,
    required this.label,
  });

  final String iconAsset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          iconAsset,
          width: 15,
          height: 15,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6C6896),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackerRowCard extends StatelessWidget {
  const _TrackerRowCard({
    required this.copy,
    required this.day,
    required this.statuses,
    required this.todayStatuses,
    required this.onTapNext,
    required this.onLongPressNext,
    required this.onTapUnavailable,
  });

  final AppCopy copy;
  final PillTrackerDay day;
  final List<PillTrackerSlotStatus> statuses;
  final List<String> todayStatuses;
  final Future<void> Function(int slotIndex) onTapNext;
  final Future<void> Function(int slotIndex) onLongPressNext;
  final Future<void> Function() onTapUnavailable;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(232),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0FA594E8),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: _DayCell(copy: copy, day: day),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: List.generate(statuses.length, (slotIndex) {
                final status = statuses[slotIndex];
                final canTapSlot =
                    day.isToday && status == PillTrackerSlotStatus.pending;
                final canWarnSlot =
                    !day.isToday && status == PillTrackerSlotStatus.pending;
                final highlightCurrent =
                    canTapSlot && slotIndex == todayStatuses.length;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: slotIndex == 0 ? 0 : 6,
                      right: slotIndex == statuses.length - 1 ? 0 : 0,
                    ),
                    child: PillBlisterSlot(
                      status: status,
                      showPill: status == PillTrackerSlotStatus.pending,
                      highlight: highlightCurrent,
                      onTap: canTapSlot
                          ? () => onTapNext(slotIndex)
                          : (canWarnSlot ? onTapUnavailable : null),
                      onLongPress: canTapSlot
                          ? () => onLongPressNext(slotIndex)
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.copy,
    required this.day,
  });

  final AppCopy copy;
  final PillTrackerDay day;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = day.isToday
        ? const Color(0xFF7B65FF)
        : day.date.weekday == DateTime.sunday
            ? const Color(0xFFFFE9EC)
            : const Color(0xFFF1F1FA);
    final textColor = day.isToday
        ? Colors.white
        : day.date.weekday == DateTime.sunday
            ? const Color(0xFFF04D5E)
            : const Color(0xFF56527F);

    final dateColor = day.isToday
        ? const Color(0xFF7B65FF)
        : day.date.weekday == DateTime.sunday
            ? const Color(0xFFF04D5E)
            : const Color(0xFF757199);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            copy.weekdayShort(day.date),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                copy.monthDay(day.date),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: dateColor,
                ),
              ),
              const SizedBox(height: 2),
              if (day.isToday)
                Text(
                  copy.todayLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF7B65FF),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class PillTrackerDay {
  const PillTrackerDay({
    required this.date,
    required this.isToday,
    required this.taken,
    required this.skipped,
    required this.goal,
  });

  final DateTime date;
  final bool isToday;
  final int taken;
  final int skipped;
  final int goal;
}

class PillBlisterSlot extends StatelessWidget {
  const PillBlisterSlot({
    super.key,
    required this.status,
    required this.showPill,
    required this.highlight,
    this.onTap,
    this.onLongPress,
  });

  final PillTrackerSlotStatus status;
  final bool showPill;
  final bool highlight;
  final Future<void> Function()? onTap;
  final Future<void> Function()? onLongPress;

  @override
  Widget build(BuildContext context) {
    final opacity = status == PillTrackerSlotStatus.skipped ? 0.3 : 1.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        splashColor: const Color(0xFF6A59ED).withAlpha(22),
        highlightColor: const Color(0xFF6A59ED).withAlpha(14),
        onTap: onTap == null
            ? null
            : () async {
                await HapticFeedback.lightImpact();
                await onTap!.call();
              },
        onLongPress: onLongPress == null
            ? null
            : () async {
                await HapticFeedback.mediumImpact();
                await onLongPress!.call();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: highlight ? 1.12 : 1.1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Image.asset(
                        'assets/blister/frame.png',
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
              if (showPill)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 5,
                    ),
                    child: Transform.scale(
                      scale: highlight ? 1.06 : 1.02,
                      child: Image.asset(
                        'assets/pills/pill.png',
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              if (status == PillTrackerSlotStatus.skipped)
                const Positioned.fill(child: _SkippedOverlay()),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkippedOverlay extends StatelessWidget {
  const _SkippedOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SkippedPainter());
  }
}

class _SkippedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xAA6A688A)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final insetX = size.width * 0.23;
    final insetY = size.height * 0.27;
    canvas.drawLine(
      Offset(insetX, insetY),
      Offset(size.width - insetX, size.height - insetY),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - insetX, insetY),
      Offset(insetX, size.height - insetY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum PillTrackerSlotStatus { pending, taken, skipped }

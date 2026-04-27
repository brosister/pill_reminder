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
  final Future<void> Function() onTapNext;
  final Future<void> Function() onLongPressNext;
  final Future<void> Function() onTapUnavailable;

  @override
  Widget build(BuildContext context) {
    final columnCount = math.max(1, columns);
    final labelWidth = copy.isKorean ? 34.0 : 44.0;
    const frameAspectRatio = 284 / 475;

    return LayoutBuilder(
      builder: (context, constraints) {
        final usableWidth = constraints.maxWidth - labelWidth - 12;
        final slotWidth = usableWidth / columnCount;
        final slotHeight = slotWidth * frameAspectRatio;

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            final isToday = day.isToday;
            final taken = day.taken;
            final skipped = day.skipped;
            final date = day.date;

            final statuses = isToday
                ? _buildTodayStatuses(todayStatuses, columnCount)
                : _buildHistoricalStatuses(
                    taken: taken,
                    skipped: skipped,
                    columns: columnCount,
                  );

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: labelWidth,
                  child: Text(
                    copy.weekdayShort(date).toUpperCase(),
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: isToday
                              ? const Color(0xFF25164D)
                              : const Color(0xFF6A5D86),
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: List.generate(columnCount, (slotIndex) {
                      final status = statuses[slotIndex];
                      final canTapSlot =
                          isToday && status == PillTrackerSlotStatus.pending;
                      final canWarnSlot =
                          !isToday && status == PillTrackerSlotStatus.pending;
                      final highlightCurrent = canTapSlot &&
                          slotIndex == todayStatuses.length;

                      return SizedBox(
                        width: slotWidth,
                        height: slotHeight,
                        child: PillBlisterSlot(
                          status: status,
                          showPill: canTapSlot,
                          highlight: highlightCurrent,
                          rowIndex: index,
                          rowCount: days.length,
                          columnIndex: slotIndex,
                          columnCount: columnCount,
                          onTap: canTapSlot
                              ? onTapNext
                              : (canWarnSlot ? onTapUnavailable : null),
                          onLongPress:
                              canTapSlot ? onLongPressNext : null,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<PillTrackerSlotStatus> _buildTodayStatuses(
    List<String> cycleStatuses,
    int columns,
  ) {
    return List.generate(columns, (index) {
      if (index >= cycleStatuses.length) return PillTrackerSlotStatus.pending;
      final value = cycleStatuses[index];
      return value == 'skipped'
          ? PillTrackerSlotStatus.skipped
          : PillTrackerSlotStatus.taken;
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
      if (index >= available) return PillTrackerSlotStatus.disabled;
      if (index < filledTaken) return PillTrackerSlotStatus.taken;
      if (index < filledTaken + filledSkipped) {
        return PillTrackerSlotStatus.skipped;
      }
      return PillTrackerSlotStatus.pending;
    });
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
    required this.rowIndex,
    required this.rowCount,
    required this.columnIndex,
    required this.columnCount,
    this.onTap,
    this.onLongPress,
  });

  final PillTrackerSlotStatus status;
  final bool showPill;
  final bool highlight;
  final int rowIndex;
  final int rowCount;
  final int columnIndex;
  final int columnCount;
  final Future<void> Function()? onTap;
  final Future<void> Function()? onLongPress;

  @override
  Widget build(BuildContext context) {
    final pillOpacity = showPill ? 1.0 : 0.0;
    final isDisabled = status == PillTrackerSlotStatus.disabled;
    final surfaceOpacity = isDisabled ? 0.3 : 1.0;

    return Opacity(
      opacity: surfaceOpacity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: _borderRadiusForPosition(),
          splashColor: const Color(0xFF2A7F62).withAlpha(28),
          highlightColor: const Color(0xFF2A7F62).withAlpha(18),
          onTap: onTap == null
              ? null
              : () async {
                  await HapticFeedback.lightImpact();
                  await onTap!.call();
                },
          onLongPress:
              onLongPress == null
                  ? null
                  : () async {
                      await HapticFeedback.mediumImpact();
                      await onLongPress!.call();
                    },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: _BlisterFrame(
                  borderRadius: _borderRadiusForPosition(),
                  columnIndex: columnIndex,
                  columnCount: columnCount,
                ),
              ),
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: _borderRadiusForPosition(),
                  child: Opacity(
                    opacity: pillOpacity,
                    child: Image.asset(
                      'assets/pills/pill.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
              if (status == PillTrackerSlotStatus.skipped)
                const Positioned.fill(child: _SkippedOverlay()),
              if (highlight)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: _borderRadiusForPosition(),
                      border: Border.all(
                        color: const Color(0xFF2A7F62).withAlpha(84),
                        width: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  BorderRadius _borderRadiusForPosition() {
    const radius = Radius.circular(20);
    return BorderRadius.only(
      topLeft: rowIndex == 0 && columnIndex == 0 ? radius : Radius.zero,
      topRight: rowIndex == 0 && columnIndex == columnCount - 1
          ? radius
          : Radius.zero,
      bottomLeft: rowIndex == rowCount - 1 && columnIndex == 0
          ? radius
          : Radius.zero,
      bottomRight:
          rowIndex == rowCount - 1 && columnIndex == columnCount - 1
              ? radius
              : Radius.zero,
    );
  }
}

class _SkippedOverlay extends StatelessWidget {
  const _SkippedOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SkippedPainter(),
    );
  }
}

class _SkippedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6A5D86).withAlpha(140)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final inset = size.shortestSide * 0.26;
    canvas.drawLine(
      Offset(inset, inset),
      Offset(size.width - inset, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BlisterFrame extends StatelessWidget {
  const _BlisterFrame({
    required this.borderRadius,
    required this.columnIndex,
    required this.columnCount,
  });

  final BorderRadius borderRadius;
  final int columnIndex;
  final int columnCount;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slice = _sliceForColumn();
          return ClipRect(
            child: Align(
              alignment: slice.alignment,
              child: SizedBox(
                width: constraints.maxWidth / slice.visibleFraction,
                height: constraints.maxHeight,
                child: Image.asset(
                  'assets/blister/frame.png',
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) => const _BlisterFallbackFill(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  _FrameSlice _sliceForColumn() {
    if (columnCount <= 1) {
      return const _FrameSlice(
        alignment: Alignment.center,
        visibleFraction: 1,
      );
    }
    if (columnIndex == 0) {
      return const _FrameSlice(
        alignment: Alignment.centerLeft,
        visibleFraction: 0.52,
      );
    }
    if (columnIndex == columnCount - 1) {
      return const _FrameSlice(
        alignment: Alignment.centerRight,
        visibleFraction: 0.52,
      );
    }
    return const _FrameSlice(
      alignment: Alignment.center,
      visibleFraction: 0.26,
    );
  }
}

class _FrameSlice {
  const _FrameSlice({
    required this.alignment,
    required this.visibleFraction,
  });

  final Alignment alignment;
  final double visibleFraction;
}

class _BlisterFallbackFill extends StatelessWidget {
  const _BlisterFallbackFill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE8EBF4),
            const Color(0xFFD8DDEA),
            const Color(0xFFF3F6FB),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: const _BlisterFallbackRim(),
    );
  }
}

class _BlisterFallbackRim extends StatelessWidget {
  const _BlisterFallbackRim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25164D).withAlpha(26),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withAlpha(140),
          ),
        ),
      ),
    );
  }
}

enum PillTrackerSlotStatus { pending, taken, skipped, disabled }

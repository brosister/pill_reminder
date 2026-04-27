import 'dart:math' as math;

import 'package:flutter/material.dart';

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
  });

  final AppCopy copy;
  final List<PillTrackerDay> days;
  final int columns;
  final List<String> todayStatuses;
  final Future<void> Function() onTapNext;
  final Future<void> Function() onLongPressNext;

  @override
  Widget build(BuildContext context) {
    final columnCount = math.max(1, columns);
    final labelWidth = copy.isKorean ? 34.0 : 44.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final usableWidth = constraints.maxWidth - labelWidth - 12;
        final slotWidth = usableWidth / columnCount;

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            final isToday = day.isToday;
            final taken = day.taken;
            final skipped = day.skipped;
            final goal = day.goal == 0 ? columnCount : day.goal;
            final date = day.date;

            final statuses = isToday
                ? _buildTodayStatuses(todayStatuses, columnCount)
                : _buildHistoricalStatuses(
                    taken: taken,
                    skipped: skipped,
                    goal: goal,
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
                      final canTapNext = isToday &&
                          status == PillTrackerSlotStatus.pending &&
                          slotIndex == todayStatuses.length &&
                          slotIndex < columnCount;
                      final slotHeight =
                          _slotHeightForRow(slotWidth, index, days.length);

                      return SizedBox(
                        width: slotWidth,
                        height: slotHeight,
                        child: PillBlisterSlot(
                          status: status,
                          showPill: status == PillTrackerSlotStatus.pending,
                          highlight: canTapNext,
                          rowIndex: index,
                          rowCount: days.length,
                          columnIndex: slotIndex,
                          columnCount: columnCount,
                          onTap: canTapNext ? onTapNext : null,
                          onLongPress:
                              canTapNext ? onLongPressNext : null,
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

  double _slotHeightForRow(double slotWidth, int rowIndex, int rowCount) {
    final isEdgeRow = rowIndex == 0 || rowIndex == rowCount - 1;
    final ratio = isEdgeRow ? (79 / 140) : (60 / 140);
    return slotWidth * ratio;
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
    required int goal,
    required int columns,
  }) {
    final normalizedGoal = math.max(0, goal);
    final available = math.min(columns, normalizedGoal == 0 ? columns : normalizedGoal);
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
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!.call(),
        onLongPress:
            onLongPress == null ? null : () => onLongPress!.call(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _BlisterFrame(
              rowIndex: rowIndex,
              rowCount: rowCount,
              columnIndex: columnIndex,
              columnCount: columnCount,
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  columnIndex == 0 ? 10 : 6,
                  rowIndex == 0 ? 12 : 8,
                  columnIndex == columnCount - 1 ? 10 : 6,
                  rowIndex == rowCount - 1 ? 10 : 6,
                ),
                child: Opacity(
                  opacity: pillOpacity,
                  child: Transform.translate(
                    offset: const Offset(0, 1),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: 78,
                        height: 42,
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: Image.asset(
                            'assets/pills/pill.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
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
    required this.rowIndex,
    required this.rowCount,
    required this.columnIndex,
    required this.columnCount,
  });

  final int rowIndex;
  final int rowCount;
  final int columnIndex;
  final int columnCount;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetForPosition(),
      fit: BoxFit.fill,
      errorBuilder: (_, __, ___) => const _BlisterFallbackFill(),
    );
  }

  String _assetForPosition() {
    final isTopRow = rowIndex == 0;
    final isBottomRow = rowIndex == rowCount - 1;
    final isLeftColumn = columnIndex == 0;
    final isRightColumn = columnIndex == columnCount - 1;

    if (isTopRow && isLeftColumn) return 'assets/blister/left_top.png';
    if (isTopRow && isRightColumn) return 'assets/blister/right_top.png';
    if (isBottomRow && isLeftColumn) return 'assets/blister/left_bottom.png';
    if (isBottomRow && isRightColumn) return 'assets/blister/right_bottom.png';
    if (isLeftColumn) return 'assets/blister/left_middle.png';
    if (isRightColumn) return 'assets/blister/right_middle.png';
    return 'assets/blister/center.png';
  }
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

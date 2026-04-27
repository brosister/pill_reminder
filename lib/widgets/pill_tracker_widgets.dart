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
        final slotHeight = math.min(62.0, math.max(46.0, slotWidth * 0.46));

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          itemCount: days.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
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

                      return SizedBox(
                        width: slotWidth,
                        height: slotHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: PillBlisterSlot(
                            status: status,
                            showPill: status == PillTrackerSlotStatus.pending,
                            highlight: canTapNext,
                            onTap: canTapNext ? onTapNext : null,
                            onLongPress:
                                canTapNext ? onLongPressNext : null,
                          ),
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
    final pillOpacity = showPill ? 1.0 : 0.0;
    final isDisabled = status == PillTrackerSlotStatus.disabled;
    final surfaceOpacity = isDisabled ? 0.3 : 1.0;

    return Opacity(
      opacity: surfaceOpacity,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap == null ? null : () => onTap!.call(),
        onLongPress:
            onLongPress == null ? null : () => onLongPress!.call(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _BlisterFrame(),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Opacity(
                  opacity: pillOpacity,
                  child: Transform.translate(
                    offset: const Offset(0, 2),
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
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF7A5AF8).withAlpha(89),
                      width: 1.2,
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
  const _BlisterFrame();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _BlisterSlice(
            asset: 'assets/blister/center.png',
            alignment: Alignment.center,
            widthFactor: 1,
            heightFactor: 1,
            fallback: const _BlisterFallbackFill(),
          ),
          const _BlisterSlice(
            asset: 'assets/blister/left_top.png',
            alignment: Alignment.topLeft,
            widthFactor: 0.56,
            heightFactor: 0.62,
          ),
          const _BlisterSlice(
            asset: 'assets/blister/right_top.png',
            alignment: Alignment.topRight,
            widthFactor: 0.56,
            heightFactor: 0.62,
          ),
          const _BlisterSlice(
            asset: 'assets/blister/left_middle.png',
            alignment: Alignment.centerLeft,
            widthFactor: 0.56,
            heightFactor: 0.48,
          ),
          const _BlisterSlice(
            asset: 'assets/blister/right_middle.png',
            alignment: Alignment.centerRight,
            widthFactor: 0.56,
            heightFactor: 0.48,
          ),
          const _BlisterSlice(
            asset: 'assets/blister/left_bottom.png',
            alignment: Alignment.bottomLeft,
            widthFactor: 0.56,
            heightFactor: 0.62,
          ),
          const _BlisterSlice(
            asset: 'assets/blister/right_bottom.png',
            alignment: Alignment.bottomRight,
            widthFactor: 0.56,
            heightFactor: 0.62,
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withAlpha(140),
                  width: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlisterSlice extends StatelessWidget {
  const _BlisterSlice({
    required this.asset,
    required this.alignment,
    required this.widthFactor,
    required this.heightFactor,
    this.fallback,
  });

  final String asset;
  final Alignment alignment;
  final double widthFactor;
  final double heightFactor;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        heightFactor: heightFactor,
        alignment: alignment,
        child: Image.asset(
          asset,
          fit: BoxFit.fill,
          errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
        ),
      ),
    );
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

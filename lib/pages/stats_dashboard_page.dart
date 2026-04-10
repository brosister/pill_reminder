import 'package:flutter/material.dart';

import '../models/app_copy.dart';
import '../models/pill_models.dart';
import '../widgets/pill_shared_widgets.dart';

class StatsDashboardPage extends StatelessWidget {
  const StatsDashboardPage({
    super.key,
    required this.copy,
    required this.weeklyCounts,
    required this.rate,
    required this.skipped,
    required this.checkedToday,
    required this.bottomPadding,
  });

  final AppCopy copy;
  final List<DailyPillCount> weeklyCounts;
  final int rate;
  final int skipped;
  final int checkedToday;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final first = MiniStatCard(
                  title: copy.sevenDaySuccess,
                  value: copy.rateText(rate),
                  subtitle: copy.adherenceStats,
                  color: const Color(0xFF7A5AF8),
                  icon: Icons.query_stats_rounded,
                );
                final second = MiniStatCard(
                  title: copy.missedCount,
                  value: '$skipped',
                  subtitle: '${copy.checkedToday} $checkedToday',
                  color: const Color(0xFFB45AF8),
                  icon: Icons.history_toggle_off_rounded,
                );
                if (constraints.maxWidth < 420) {
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
            const SizedBox(height: 18),
            CardShell(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.weeklyFlow,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1830),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    copy.weeklyFlowHint,
                    style: const TextStyle(color: Color(0xFF8A859B)),
                  ),
                  const SizedBox(height: 16),
                  WeeklyBarChart(copy: copy, data: weeklyCounts),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/app_copy.dart';
import '../models/pill_models.dart';
import '../widgets/pill_shared_widgets.dart';

class PillHistoryPage extends StatelessWidget {
  const PillHistoryPage({
    super.key,
    required this.copy,
    required this.logs,
  });

  final AppCopy copy;
  final List<DoseLog> logs;

  @override
  Widget build(BuildContext context) {
    return BottomBannerPageScaffold(
      title: copy.historyTitle,
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
            SectionIntro(
              description: copy.historyHint,
              icon: Icons.history_rounded,
            ),
            const SizedBox(height: 18),
            MedicationLogCard(
              copy: copy,
              logs: logs,
              emptyMessage: copy.noMoreHistory,
            ),
          ],
        ),
      ),
    );
  }
}

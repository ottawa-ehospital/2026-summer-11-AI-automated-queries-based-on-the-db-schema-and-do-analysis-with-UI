import 'package:flutter/material.dart';

import '../presentation/vitals_history_styles.dart';

class VitalsHistorySummaryBanner extends StatelessWidget {
  final String title;
  final String subtitle;

  const VitalsHistorySummaryBanner({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: VitalsHistoryStyles.bannerPadding,
      decoration: VitalsHistoryStyles.summaryDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: VitalsHistoryStyles.summaryIconDecoration,
            child: const Icon(Icons.history, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: VitalsHistoryStyles.summaryTitle),
              Text(subtitle, style: VitalsHistoryStyles.summarySubtitle),
            ],
          ),
        ],
      ),
    );
  }
}

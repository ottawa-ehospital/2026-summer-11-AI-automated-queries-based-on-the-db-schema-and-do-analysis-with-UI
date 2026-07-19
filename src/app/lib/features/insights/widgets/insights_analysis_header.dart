import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../presentation/insights_styles.dart';

class InsightsAnalysisHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? mergedPairsLabel;

  const InsightsAnalysisHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.mergedPairsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: InsightsStyles.headerPadding,
      decoration: InsightsStyles.headerDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: InsightsStyles.headerIconDecoration,
                child: const Icon(Icons.insights, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: InsightsStyles.headerTitle),
                    const SizedBox(height: 4),
                    Text(subtitle, style: InsightsStyles.headerSubtitle),
                  ],
                ),
              ),
            ],
          ),
          if (mergedPairsLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: InsightsStyles.headerBadgePadding,
              decoration: InsightsStyles.headerBadgeDecoration,
              child: Text(mergedPairsLabel!, style: InsightsStyles.headerBadgeText),
            ),
          ],
        ],
      ),
    );
  }
}

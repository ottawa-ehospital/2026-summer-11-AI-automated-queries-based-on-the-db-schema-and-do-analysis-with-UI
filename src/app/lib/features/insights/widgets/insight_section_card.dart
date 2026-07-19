import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../presentation/insights_styles.dart';

class InsightSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const InsightSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: InsightsStyles.sectionMargin,
      decoration: InsightsStyles.sectionCardDecoration,
      child: Padding(
        padding: InsightsStyles.sectionPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: InsightsStyles.sectionIconDecoration,
                  child: Icon(icon, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: InsightsStyles.sectionTitle),
                      Text(subtitle, style: InsightsStyles.sectionSubtitle),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

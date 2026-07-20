import 'package:flutter/material.dart';

import '../presentation/insights_styles.dart';

class HealthInsightCard extends StatelessWidget {
  final Map<String, dynamic> insight;
  final Color color;
  final Color backgroundColor;
  final IconData icon;
  final String severityLabel;

  const HealthInsightCard({
    super.key,
    required this.insight,
    required this.color,
    required this.backgroundColor,
    required this.icon,
    required this.severityLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: InsightsStyles.severityCardDecoration(color, backgroundColor),
      child: Padding(
        padding: InsightsStyles.sectionPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: InsightsStyles.severityIconDecoration(color),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: InsightsStyles.severityBadgeDecoration(color),
                        child: Text(
                          severityLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(insight['title'] as String, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(insight['description'] as String, style: InsightsStyles.insightBody),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.source_outlined, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Sources: ${insight["sources"]}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

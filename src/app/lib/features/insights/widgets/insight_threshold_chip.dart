import 'package:flutter/material.dart';

import '../presentation/insights_styles.dart';

class InsightThresholdChip extends StatelessWidget {
  final String label;
  final Color color;

  const InsightThresholdChip({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: InsightsStyles.thresholdChipDecoration(color),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

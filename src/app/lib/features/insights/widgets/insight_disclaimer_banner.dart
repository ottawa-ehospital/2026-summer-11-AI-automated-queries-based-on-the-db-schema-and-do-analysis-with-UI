import 'package:flutter/material.dart';

import '../presentation/insights_styles.dart';

class InsightDisclaimerBanner extends StatelessWidget {
  final String text;

  const InsightDisclaimerBanner({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: InsightsStyles.disclaimerMargin,
      padding: InsightsStyles.disclaimerPadding,
      decoration: InsightsStyles.disclaimerDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12, color: Colors.orange.shade800, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

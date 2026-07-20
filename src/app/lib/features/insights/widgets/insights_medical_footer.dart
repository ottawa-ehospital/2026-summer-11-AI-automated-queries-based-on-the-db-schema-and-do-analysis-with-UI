import 'package:flutter/material.dart';

import '../presentation/insights_styles.dart';

class InsightsMedicalFooter extends StatelessWidget {
  final String text;

  const InsightsMedicalFooter({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: InsightsStyles.footerPadding,
      decoration: InsightsStyles.footerDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.medical_information_outlined, color: Colors.orange.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: InsightsStyles.footerText)),
        ],
      ),
    );
  }
}

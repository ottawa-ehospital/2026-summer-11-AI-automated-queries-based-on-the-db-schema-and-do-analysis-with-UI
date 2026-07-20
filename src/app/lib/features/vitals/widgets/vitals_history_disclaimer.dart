import 'package:flutter/material.dart';

import '../presentation/vitals_history_styles.dart';

class VitalsHistoryDisclaimer extends StatelessWidget {
  final String text;

  const VitalsHistoryDisclaimer({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: VitalsHistoryStyles.disclaimerMargin,
      padding: VitalsHistoryStyles.disclaimerPadding,
      decoration: VitalsHistoryStyles.disclaimerDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.orange.shade800, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

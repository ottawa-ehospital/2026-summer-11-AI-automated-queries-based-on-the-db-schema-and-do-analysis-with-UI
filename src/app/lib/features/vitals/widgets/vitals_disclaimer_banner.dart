import 'package:flutter/material.dart';

import '../presentation/vitals_styles.dart';

class VitalsDisclaimerBanner extends StatelessWidget {
  final String text;

  const VitalsDisclaimerBanner({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: VitalsStyles.bannerMargin,
      padding: VitalsStyles.disclaimerPadding,
      decoration: VitalsStyles.disclaimerDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037))),
          ),
        ],
      ),
    );
  }
}

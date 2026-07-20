import 'package:flutter/material.dart';

import '../presentation/vitals_styles.dart';

class VitalsWarningBanner extends StatelessWidget {
  final String text;

  const VitalsWarningBanner({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: VitalsStyles.warningPadding,
      decoration: VitalsStyles.warningDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: VitalsStyles.warningIconDecoration,
            child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

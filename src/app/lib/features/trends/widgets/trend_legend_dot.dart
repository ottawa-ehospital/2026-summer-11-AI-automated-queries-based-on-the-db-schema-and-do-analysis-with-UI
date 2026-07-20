import 'package:flutter/material.dart';

import '../presentation/trend_styles.dart';

class TrendLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const TrendLegendDot({
    super.key,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TrendStyles.legendLabel),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

class InsightCorrelationRow extends StatelessWidget {
  final String label;
  final double value;
  final String badgeLabel;
  final String interpretation;
  final Color color;
  final Color strengthColor;

  const InsightCorrelationRow({
    super.key,
    required this.label,
    required this.value,
    required this.badgeLabel,
    required this.interpretation,
    required this.color,
    required this.strengthColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.swap_horiz, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: AppRadii.radius(6),
                child: LinearProgressIndicator(
                  value: value.abs(),
                  minHeight: 10,
                  backgroundColor: Colors.grey.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'r = ${value.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: strengthColor),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: strengthColor.withValues(alpha: 0.12),
                borderRadius: AppRadii.radius(AppSpacing.sm),
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: strengthColor),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(interpretation, style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
          ],
        ),
      ],
    );
  }
}

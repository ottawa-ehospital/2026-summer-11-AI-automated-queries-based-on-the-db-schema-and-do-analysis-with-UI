import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

class InsightsCountHeader extends StatelessWidget {
  final String label;

  const InsightsCountHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
          child: const Icon(Icons.bar_chart, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ],
    );
  }
}

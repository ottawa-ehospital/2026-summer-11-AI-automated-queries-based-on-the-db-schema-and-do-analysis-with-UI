import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import 'simulation_day_chip.dart';

class SimulationProgressPanel extends StatelessWidget {
  final bool done;
  final int progress;
  final int total;
  final String statusText;

  const SimulationProgressPanel({
    super.key,
    required this.done,
    required this.progress,
    required this.total,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: AppRadii.radius(AppSpacing.sm),
          child: LinearProgressIndicator(
            value: done ? 1.0 : progress / total,
            minHeight: 10,
            backgroundColor: AppColors.primarySoft,
            valueColor: AlwaysStoppedAnimation<Color>(done ? Colors.green : AppColors.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(total, (index) {
            final dayNum = index + 1;
            return SimulationDayChip(
              day: dayNum,
              uploaded: index < progress,
              current: index == progress && !done,
            );
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Icon(
              done ? Icons.check_circle : Icons.cloud_upload_outlined,
              size: 16,
              color: done ? Colors.green : AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: done ? Colors.green : AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

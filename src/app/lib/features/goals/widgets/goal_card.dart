import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../presentation/goal_styles.dart';

class GoalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String progressLabel;
  final String editTooltip;
  final double actual;
  final double goal;
  final Color color;
  final VoidCallback onEdit;

  const GoalCard({
    super.key,
    required this.icon,
    required this.title,
    required this.progressLabel,
    required this.editTooltip,
    required this.actual,
    required this.goal,
    required this.color,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (actual / goal).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: GoalStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: GoalStyles.iconBadgeDecoration(color),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700))),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                onPressed: onEdit,
                tooltip: editTooltip,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadii.radius(AppRadii.sm),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: color.withAlpha(31),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(progressLabel, style: AppTypography.caption.copyWith(fontSize: 13)),
              Text('$percent%', style: GoalStyles.progressPercent(color)),
            ],
          ),
        ],
      ),
    );
  }
}

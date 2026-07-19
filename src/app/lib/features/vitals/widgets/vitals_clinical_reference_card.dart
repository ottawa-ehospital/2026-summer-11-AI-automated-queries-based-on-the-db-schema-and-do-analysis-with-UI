import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../presentation/vitals_styles.dart';

class VitalsClinicalStatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const VitalsClinicalStatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class VitalsClinicalReferenceCard extends StatelessWidget {
  final String title;
  final String sourceLabel;
  final List<VitalsClinicalStatData> stats;

  const VitalsClinicalReferenceCard({
    super.key,
    required this.title,
    required this.sourceLabel,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: VitalsStyles.clinicalCardDecoration,
      padding: VitalsStyles.clinicalCardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: VitalsStyles.clinicalHeaderIconDecoration,
                child: const Icon(Icons.history_edu, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(title, style: VitalsStyles.clinicalTitle),
              const Spacer(),
              Text(sourceLabel, style: VitalsStyles.clinicalSource),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                _ClinicalStat(data: stats[i]),
                if (i < stats.length - 1) const _ClinicalDivider(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ClinicalStat extends StatelessWidget {
  final VitalsClinicalStatData data;

  const _ClinicalStat({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: VitalsStyles.clinicalStatIconDecoration(data.color),
          child: Icon(data.icon, color: data.color, size: 18),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(data.value, style: VitalsStyles.clinicalStatValue),
        const SizedBox(height: 2),
        Text(data.label, style: VitalsStyles.clinicalStatLabel),
      ],
    );
  }
}

class _ClinicalDivider extends StatelessWidget {
  const _ClinicalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 50, color: Colors.white.withValues(alpha: 0.2));
  }
}

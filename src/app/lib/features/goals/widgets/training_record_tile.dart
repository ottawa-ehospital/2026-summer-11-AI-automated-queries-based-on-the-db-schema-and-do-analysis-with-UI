import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/l10n.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../models/training_record.dart';
import '../presentation/goal_styles.dart';

class TrainingRecordTile extends StatelessWidget {
  final TrainingRecord record;

  const TrainingRecordTile({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final metrics = _metrics(l10n);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: GoalStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: GoalStyles.iconBadgeDecoration(AppColors.primary),
                child: const Icon(
                  Icons.fitness_center_outlined,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.displayType,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateLabel(context),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: metrics
                  .map(
                    (metric) => _MetricChip(label: metric.$1, value: metric.$2),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _dateLabel(BuildContext context) {
    final start = record.startTime;
    if (start == null) return context.l10n.trainingRecordsUnknownDate;
    return DateFormat('MMM d, h:mm a').format(start.toLocal());
  }

  List<(String, String)> _metrics(AppLocalizations l10n) {
    return [
      if (record.durationSeconds > 0)
        (l10n.trainingRecordsDurationLabel, _duration(record.durationSeconds)),
      if (record.distanceMeters != null)
        (l10n.trainingRecordsDistanceLabel, _distance(record.distanceMeters!)),
      if (record.activeEnergyKcal != null)
        (
          l10n.trainingRecordsEnergyLabel,
          '${record.activeEnergyKcal!.round()} ${l10n.kcalUnit}',
        ),
      if (record.steps != null)
        (l10n.trainingRecordsStepsLabel, '${record.steps} ${l10n.stepsUnit}'),
      if (record.sourceProvider != null)
        (l10n.trainingRecordsSourceLabel, _source(record.sourceProvider!)),
    ];
  }

  String _duration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours <= 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  String _distance(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.round()} m';
  }

  String _source(String source) {
    return source
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label: $value',
        style: AppTypography.caption.copyWith(color: AppColors.textBody),
      ),
    );
  }
}

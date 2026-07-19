import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../ui/ui.dart';
import '../models/training_record.dart';
import 'training_record_tile.dart';

class TrainingRecordsTab extends StatelessWidget {
  final List<TrainingRecord> records;
  final bool loading;
  final bool syncing;
  final String? errorMessage;
  final String? statusMessage;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onSync;

  const TrainingRecordsTab({
    super.key,
    required this.records,
    required this.loading,
    required this.syncing,
    required this.errorMessage,
    required this.statusMessage,
    required this.onRefresh,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.trainingRecordsTitle,
                style: AppTypography.sectionTitle,
              ),
            ),
            IconButton(
              tooltip: l10n.trainingRecordsRefreshTooltip,
              onPressed: loading || syncing ? null : onRefresh,
              icon: const Icon(Icons.refresh_outlined),
            ),
            IconButton(
              tooltip: l10n.trainingRecordsSyncTooltip,
              onPressed: loading || syncing ? null : onSync,
              icon: syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_outlined),
            ),
          ],
        ),
        if (statusMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _StatusBanner(message: statusMessage!, error: false),
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _StatusBanner(message: errorMessage!, error: true),
        ],
        const SizedBox(height: AppSpacing.md),
        if (loading)
          _CenteredState(
            icon: Icons.history_toggle_off_outlined,
            text: l10n.trainingRecordsLoading,
            loading: true,
          )
        else if (records.isEmpty)
          _CenteredState(
            icon: Icons.fitness_center_outlined,
            text: l10n.trainingRecordsEmpty,
          )
        else
          ...records.expand(
            (record) => [
              TrainingRecordTile(record: record),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;
  final bool error;

  const _StatusBanner({required this.message, required this.error});

  @override
  Widget build(BuildContext context) {
    final color = error ? AppColors.danger : Colors.green;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        message,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CenteredState extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool loading;

  const _CenteredState({
    required this.icon,
    required this.text,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.dialog),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (loading)
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else
            Icon(icon, color: AppColors.textMuted, size: 30),
          const SizedBox(height: AppSpacing.md),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../ui/ui.dart';

class DataSourcesDialog extends StatelessWidget {
  const DataSourcesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadii.radius(AppRadii.dialog)),
      titlePadding: AppSpacing.dialogTitle,
      contentPadding: AppSpacing.dialogContent,
      actionsPadding: AppSpacing.dialogActions,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
            child: const Icon(Icons.source_outlined, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(l10n.dataSourcesTitle, style: AppTypography.sectionTitle)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),
            _SourceItem(
              icon: Icons.local_hospital_outlined,
              title: l10n.sourceClinicalTitle,
              description: l10n.sourceClinicalDescription,
            ),
            _SourceItem(
              icon: Icons.watch_outlined,
              title: l10n.sourceWearableTitle,
              description: l10n.sourceWearableDescription,
            ),
            _SourceItem(
              icon: Icons.psychology_outlined,
              title: l10n.sourceAssistantTitle,
              description: l10n.sourceAssistantDescription,
            ),
            _SourceItem(
              icon: Icons.monitor_heart_outlined,
              title: l10n.sourceVitalsTitle,
              description: l10n.sourceVitalsDescription,
            ),
            _SourceItem(
              icon: Icons.calculate_outlined,
              title: l10n.sourceBmiTitle,
              description: l10n.sourceBmiDescription,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: AppRadii.radius(AppRadii.sm),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                l10n.medicalAdviceShortDisclaimer,
                style: TextStyle(fontSize: 12, color: Colors.orange.shade800, height: 1.5),
              ),
            ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadii.radius(AppRadii.md)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
            child: Text(l10n.closeButton, style: AppTypography.button.copyWith(fontSize: 15)),
          ),
        ),
      ],
    );
  }
}

class _SourceItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _SourceItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                const SizedBox(height: 3),
                Text(description, style: AppTypography.caption.copyWith(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

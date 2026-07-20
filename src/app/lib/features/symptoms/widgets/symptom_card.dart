import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../ui/ui.dart';
import '../presentation/symptom_styles.dart';

class SymptomCard extends StatelessWidget {
  final Map<String, dynamic> symptom;
  final Color Function(int severity) severityColor;
  final String Function(int severity) severityLabel;
  final String Function(String iso) formatTime;
  final VoidCallback onDelete;

  const SymptomCard({
    super.key,
    required this.symptom,
    required this.severityColor,
    required this.severityLabel,
    required this.formatTime,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final severity = symptom["severity"] as int;
    final color = severityColor(severity);
    final notes = symptom["notes"] as String;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: SymptomStyles.cardDecoration,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                symptom["name"] as String,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: SymptomStyles.badgeDecoration(color),
              child: Text(
                l10n.severityBadgeLabel(severityLabel(severity), severity),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(notes, style: AppTypography.caption),
            ],
            const SizedBox(height: 4),
            Text(formatTime(symptom["timestamp"] as String), style: AppTypography.caption.copyWith(fontSize: 11)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../ui/ui.dart';
import '../presentation/medication_styles.dart';

class MedicationCard extends StatelessWidget {
  final Map<String, dynamic> medication;
  final VoidCallback onToggleTaken;
  final VoidCallback onDelete;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.onToggleTaken,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final taken = medication["takenToday"] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: MedicationStyles.cardDecoration,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: GestureDetector(
          onTap: onToggleTaken,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: taken ? Colors.green.shade50 : AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              taken ? Icons.check_circle : Icons.circle_outlined,
              color: taken ? Colors.green : AppColors.primary,
              size: 24,
            ),
          ),
        ),
        title: Text(
          medication["name"] as String,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
            decoration: taken ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          l10n.medicationSummary(
            medication["dosage"] as String,
            medication["frequency"] as String,
            medication["time"] as String,
          ),
          style: AppTypography.caption,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

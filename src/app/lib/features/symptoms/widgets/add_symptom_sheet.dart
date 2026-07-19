import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../ui/ui.dart';
import '../presentation/symptom_styles.dart';

class AddSymptomSheet extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController notesController;
  final double severity;
  final ValueChanged<double> onSeverityChanged;
  final Color Function(int severity) severityColor;
  final String Function(int severity) severityLabel;
  final VoidCallback onAdd;

  const AddSymptomSheet({
    super.key,
    required this.nameController,
    required this.notesController,
    required this.severity,
    required this.onSeverityChanged,
    required this.severityColor,
    required this.severityLabel,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final severityInt = severity.round();
    final color = severityColor(severityInt);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.logSymptomTitle, style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: l10n.symptomNameLabel,
              prefixIcon: const Icon(Icons.sick_outlined, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.severityLabel, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: SymptomStyles.badgeDecoration(color),
                child: Text(
                  l10n.severityValueLabel(severityInt, severityLabel(severityInt)),
                  style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13),
                ),
              ),
            ],
          ),
          Slider(
            value: severity,
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: color,
            onChanged: onSeverityChanged,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: notesController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.notesOptionalLabel,
              prefixIcon: const Icon(Icons.notes_outlined, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onAdd, child: Text(l10n.logSymptomTitle)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../ui/ui.dart';

class AddMedicationSheet extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController dosageController;
  final TextEditingController frequencyController;
  final TextEditingController timeController;
  final VoidCallback onAdd;

  const AddMedicationSheet({
    super.key,
    required this.nameController,
    required this.dosageController,
    required this.frequencyController,
    required this.timeController,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.addMedicationTitle, style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.lg),
          _field(nameController, l10n.medicationNameLabel, Icons.medication_outlined),
          const SizedBox(height: 10),
          _field(dosageController, l10n.dosageLabel, Icons.colorize_outlined),
          const SizedBox(height: 10),
          _field(frequencyController, l10n.frequencyLabel, Icons.repeat),
          const SizedBox(height: 10),
          _field(timeController, l10n.timeLabel, Icons.access_time),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onAdd, child: Text(l10n.addMedicationTitle)),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppColors.primary)),
    );
  }
}

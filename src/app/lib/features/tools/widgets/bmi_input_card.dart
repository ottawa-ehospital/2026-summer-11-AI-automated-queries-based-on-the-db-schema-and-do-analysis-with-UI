import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../ui/ui.dart';
import '../presentation/bmi_styles.dart';

class BmiInputCard extends StatelessWidget {
  final TextEditingController heightController;
  final TextEditingController weightController;
  final VoidCallback onCalculate;

  const BmiInputCard({
    super.key,
    required this.heightController,
    required this.weightController,
    required this.onCalculate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BmiStyles.cardDecoration(),
      child: Column(
        children: [
          TextField(
            controller: heightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.heightCmLabel,
              prefixIcon: const Icon(Icons.height, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: weightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.weightKgLabel,
              prefixIcon: const Icon(Icons.monitor_weight_outlined, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onCalculate, child: Text(l10n.calculateBmiButton)),
          ),
        ],
      ),
    );
  }
}

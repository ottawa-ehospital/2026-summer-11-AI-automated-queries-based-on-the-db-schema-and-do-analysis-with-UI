import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../presentation/vitals_styles.dart';

class VitalsRangeOption {
  final String label;
  final int days;

  const VitalsRangeOption({required this.label, required this.days});
}

class VitalsRangeFilter extends StatelessWidget {
  final int selectedDays;
  final List<VitalsRangeOption> options;
  final ValueChanged<int> onSelected;

  const VitalsRangeFilter({
    super.key,
    required this.selectedDays,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((option) {
        final selected = selectedDays == option.days;
        return GestureDetector(
          onTap: () => onSelected(option.days),
          child: AnimatedContainer(
            duration: VitalsStyles.shortAnimation,
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            padding: VitalsStyles.rangeChipPadding,
            decoration: VitalsStyles.rangeChipDecoration(selected: selected),
            child: Text(
              option.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

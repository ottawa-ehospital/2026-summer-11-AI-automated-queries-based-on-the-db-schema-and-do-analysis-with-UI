import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../ui/ui.dart';
import '../presentation/bmi_styles.dart';

class BmiReferenceCard extends StatelessWidget {
  const BmiReferenceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BmiStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.bmiReferenceTitle, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          _RefRow(range: "< 18.5", label: l10n.bmiUnderweight, color: Colors.blue),
          _RefRow(range: "18.5 - 24.9", label: l10n.bmiNormal, color: Colors.green),
          _RefRow(range: "25.0 - 29.9", label: l10n.bmiOverweight, color: Colors.orange),
          _RefRow(range: ">= 30.0", label: l10n.bmiObese, color: Colors.red),
        ],
      ),
    );
  }
}

class _RefRow extends StatelessWidget {
  final String range;
  final String label;
  final Color color;

  const _RefRow({required this.range, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          SizedBox(width: 100, child: Text(range, style: AppTypography.caption.copyWith(fontSize: 13))),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

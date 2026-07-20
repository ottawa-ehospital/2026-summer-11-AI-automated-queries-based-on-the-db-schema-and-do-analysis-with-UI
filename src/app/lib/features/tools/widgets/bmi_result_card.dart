import 'package:flutter/material.dart';
import '../../../ui/ui.dart';
import '../presentation/bmi_styles.dart';

class BmiResultCard extends StatelessWidget {
  final double bmi;
  final String category;
  final Color categoryColor;

  const BmiResultCard({
    super.key,
    required this.bmi,
    required this.category,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BmiStyles.cardDecoration(accent: categoryColor),
      child: Column(
        children: [
          Text(
            bmi.toStringAsFixed(1),
            style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: categoryColor),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.12),
              borderRadius: AppRadii.radius(AppRadii.dialog),
            ),
            child: Text(
              category,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: categoryColor),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _BmiScale(bmi: bmi, categoryColor: categoryColor),
        ],
      ),
    );
  }
}

class _BmiScale extends StatelessWidget {
  final double bmi;
  final Color categoryColor;

  const _BmiScale({required this.bmi, required this.categoryColor});

  @override
  Widget build(BuildContext context) {
    final ranges = [
      (Colors.blue, 0.0, 18.5),
      (Colors.green, 18.5, 25.0),
      (Colors.orange, 25.0, 30.0),
      (Colors.red, 30.0, 40.0),
    ];
    final clampedBmi = bmi.clamp(10.0, 40.0);
    final position = ((clampedBmi - 10) / 30).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: AppRadii.radius(AppSpacing.sm),
          child: Row(
            children: ranges.map((r) {
              final span = r.$3 - r.$2;
              final flex = (span / 30 * 100).round();
              return Expanded(flex: flex, child: Container(height: 12, color: r.$1));
            }).toList(),
          ),
        ),
        LayoutBuilder(
          builder: (ctx, constraints) {
            final indicatorX = (position * constraints.maxWidth).clamp(6.0, constraints.maxWidth - 6.0);
            return Stack(
              children: [
                SizedBox(height: 20, width: constraints.maxWidth),
                Positioned(
                  left: indicatorX - 6,
                  top: 4,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

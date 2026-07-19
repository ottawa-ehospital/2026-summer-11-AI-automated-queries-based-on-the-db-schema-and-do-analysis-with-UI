import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../presentation/vitals_history_styles.dart';

class VitalsHistoryDataCard extends StatelessWidget {
  final String title;
  final List<dynamic> items;
  final IconData icon;
  final String emptyLabel;
  final String Function(int count) moreLabelBuilder;
  final Widget Function(dynamic item) tileBuilder;

  const VitalsHistoryDataCard({
    super.key,
    required this.title,
    required this.items,
    required this.icon,
    required this.emptyLabel,
    required this.moreLabelBuilder,
    required this.tileBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: VitalsHistoryStyles.dataCardMargin,
      decoration: VitalsHistoryStyles.dataCardDecoration,
      child: Padding(
        padding: VitalsHistoryStyles.dataCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: VitalsHistoryStyles.relatedIconDecoration,
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Text(title, style: VitalsHistoryStyles.dataCardTitle),
                const Spacer(),
                if (items.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: AppRadii.radius(AppRadii.dialog),
                    ),
                    child: Text(
                      '${items.length}',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            if (items.isEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(emptyLabel, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ] else ...[
              const SizedBox(height: 14),
              ...items.take(5).map(tileBuilder),
              if (items.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(moreLabelBuilder(items.length - 5), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

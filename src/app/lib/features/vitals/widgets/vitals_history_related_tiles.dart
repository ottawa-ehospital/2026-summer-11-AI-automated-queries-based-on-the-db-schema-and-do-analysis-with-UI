import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../presentation/vitals_history_styles.dart';

class VitalsHistoryLabTestTile extends StatelessWidget {
  final String type;
  final String result;
  final Color resultColor;
  final String statusLine;
  final String locationLine;

  const VitalsHistoryLabTestTile({
    super.key,
    required this.type,
    required this.result,
    required this.resultColor,
    required this.statusLine,
    required this.locationLine,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: VitalsHistoryStyles.labTileGap,
      child: Container(
        padding: VitalsHistoryStyles.labTilePadding,
        decoration: VitalsHistoryStyles.labTileDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                  decoration: VitalsHistoryStyles.resultBadgeDecoration(resultColor),
                  child: Text(result, style: TextStyle(fontSize: 12, color: resultColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(statusLine, style: VitalsHistoryStyles.relatedSecondary),
            Text(locationLine, style: VitalsHistoryStyles.relatedSecondary),
          ],
        ),
      ),
    );
  }
}

class VitalsHistoryTextTile extends StatelessWidget {
  final String primary;
  final String? secondary;
  final String? tertiary;

  const VitalsHistoryTextTile({
    super.key,
    required this.primary,
    this.secondary,
    this.tertiary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: VitalsHistoryStyles.relatedTileGap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(primary, style: VitalsHistoryStyles.relatedPrimary),
          if (secondary != null) Text(secondary!, style: VitalsHistoryStyles.relatedSecondary),
          if (tertiary != null) Text(tertiary!, style: VitalsHistoryStyles.relatedSecondary),
        ],
      ),
    );
  }
}

class VitalsHistoryRiskTile extends StatelessWidget {
  final String primary;
  final String badge;
  final Color badgeColor;
  final String secondary;

  const VitalsHistoryRiskTile({
    super.key,
    required this.primary,
    required this.badge,
    required this.badgeColor,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: VitalsHistoryStyles.relatedTileGap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(primary, style: VitalsHistoryStyles.relatedPrimary),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: VitalsHistoryStyles.riskBadgeDecoration(badgeColor),
                      child: Text(badge, style: TextStyle(fontSize: 11, color: badgeColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Text(secondary, style: VitalsHistoryStyles.relatedSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VitalsHistoryDiagnosisTile extends StatelessWidget {
  final String code;
  final String date;
  final String description;

  const VitalsHistoryDiagnosisTile({
    super.key,
    required this.code,
    required this.date,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: VitalsHistoryStyles.relatedTileGap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: VitalsHistoryStyles.codeBadgeDecoration,
                      child: Text(code, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(date, style: VitalsHistoryStyles.relatedSecondary),
                  ],
                ),
                const SizedBox(height: 2),
                Text(description, style: VitalsHistoryStyles.relatedDescription),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

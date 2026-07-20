import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

class VitalsHistoryStyles {
  static const bodyPadding = EdgeInsets.fromLTRB(20, 20, 20, 32);
  static const bannerPadding = EdgeInsets.all(AppSpacing.xl);
  static const disclaimerMargin = EdgeInsets.only(bottom: 14);
  static const disclaimerPadding = EdgeInsets.all(AppSpacing.md);
  static const dataCardMargin = EdgeInsets.only(bottom: 14);
  static const dataCardPadding = EdgeInsets.all(18);
  static const relatedTileGap = EdgeInsets.only(bottom: AppSpacing.sm);
  static const labTileGap = EdgeInsets.only(bottom: 10);
  static const labTilePadding = EdgeInsets.all(10);

  static const summaryDecoration = BoxDecoration(
    gradient: AppGradients.primary,
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.dialog)),
    boxShadow: [
      BoxShadow(
        color: Color(0x4D6A1B9A),
        blurRadius: 14,
        offset: Offset(0, 6),
      ),
    ],
  );

  static const summaryIconDecoration = BoxDecoration(
    color: Color(0x26FFFFFF),
    shape: BoxShape.circle,
  );

  static BoxDecoration get emptyDecoration => const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.dialog)),
        boxShadow: [
          BoxShadow(color: Color(0x126A1B9A), blurRadius: 10),
        ],
      );

  static BoxDecoration get disclaimerDecoration => BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: AppRadii.radius(AppSpacing.md),
        border: Border.all(color: Colors.orange.shade300),
      );

  static const dataCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.dialog)),
    boxShadow: AppShadows.primarySoft,
  );

  static const relatedIconDecoration = BoxDecoration(
    color: AppColors.primarySoft,
    shape: BoxShape.circle,
  );

  static BoxDecoration get labTileDecoration => BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: AppRadii.radius(AppSpacing.sm),
        border: Border.all(color: Colors.grey.shade200),
      );

  static BoxDecoration resultBadgeDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadii.radius(4),
      );

  static BoxDecoration riskBadgeDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.radius(4),
      );

  static BoxDecoration get codeBadgeDecoration => BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadii.radius(4),
      );

  static BoxDecoration tabDecoration({required bool selected, required Color color}) => BoxDecoration(
        color: selected ? color : Colors.white,
        borderRadius: AppRadii.radius(AppRadii.lg),
        boxShadow: [
          BoxShadow(
            color: (selected ? color : Colors.black).withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      );

  static const summaryTitle = TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold);
  static const summarySubtitle = TextStyle(color: Color(0xCCFFFFFF), fontSize: 13);
  static const dataCardTitle = TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark);
  static const relatedPrimary = TextStyle(fontWeight: FontWeight.w600, fontSize: 14);
  static const relatedSecondary = TextStyle(fontSize: 12, color: Colors.black54);
  static const relatedDescription = TextStyle(fontWeight: FontWeight.w600, fontSize: 13);
  static const chartTitle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  static const chartLegend = TextStyle(fontSize: 12, color: Colors.black54);
  static const chartAxis = TextStyle(fontSize: 9, color: Colors.black54);
}

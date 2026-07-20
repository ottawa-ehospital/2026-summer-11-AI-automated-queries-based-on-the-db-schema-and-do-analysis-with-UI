import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

class TrendStyles {
  static const bodyPadding = EdgeInsets.fromLTRB(20, 24, 20, 32);
  static const bannerMargin = EdgeInsets.only(bottom: AppSpacing.lg);
  static const bannerPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 10);
  static const metricCardPadding = EdgeInsets.all(AppSpacing.xl);

  static BoxDecoration get disclaimerDecoration => BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade300),
        borderRadius: AppRadii.radius(AppRadii.sm),
      );

  static const metricCardDecoration = BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.dialog)),
    boxShadow: AppShadows.primarySoft,
  );

  static BoxDecoration metricIconDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      );

  static BoxDecoration statusChipDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadii.radius(6),
      );

  static BoxDecoration insightDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: AppRadii.radius(AppSpacing.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      );

  static const providerBadgeDecoration = BoxDecoration(
    color: AppColors.primarySoft,
    borderRadius: BorderRadius.all(Radius.circular(5)),
  );

  static const legendLabel = TextStyle(fontSize: 13, color: AppColors.textMuted);
  static const metricTitle = TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark);
  static const metricDescription = TextStyle(fontSize: 11, color: AppColors.textMuted);
  static const insightBody = TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.4);
}

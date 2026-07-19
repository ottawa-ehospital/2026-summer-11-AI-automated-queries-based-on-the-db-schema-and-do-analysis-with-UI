import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

class VitalsStyles {
  static const shortAnimation = Duration(milliseconds: 180);
  static const mediumAnimation = Duration(milliseconds: 200);

  static const bodyPadding = EdgeInsets.fromLTRB(20, 20, 20, 100);
  static const bannerMargin = EdgeInsets.only(bottom: AppSpacing.lg);
  static const syncPadding = EdgeInsets.all(14);
  static const warningPadding = EdgeInsets.all(AppSpacing.lg);
  static const disclaimerPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 10);
  static const clinicalCardPadding = EdgeInsets.all(20);
  static const rangeChipPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 7);
  static const metricTabPadding = EdgeInsets.symmetric(horizontal: 18, vertical: 10);
  static const metricCardPadding = EdgeInsets.fromLTRB(16, 20, 16, 16);

  static BoxDecoration get disclaimerDecoration => BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade300),
        borderRadius: AppRadii.radius(AppRadii.sm),
      );

  static BoxDecoration get syncingDecoration => BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadii.radius(AppRadii.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      );

  static BoxDecoration syncResultDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadii.radius(AppRadii.lg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      );

  static BoxDecoration get warningDecoration => BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: AppRadii.radius(AppRadii.xl),
        border: Border.all(color: Colors.red.shade200),
      );

  static BoxDecoration get warningIconDecoration => BoxDecoration(
        color: Colors.red.shade100,
        shape: BoxShape.circle,
      );

  static const clinicalCardDecoration = BoxDecoration(
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

  static BoxDecoration get clinicalHeaderIconDecoration => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      );

  static BoxDecoration clinicalStatIconDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      );

  static BoxDecoration rangeChipDecoration({required bool selected}) => BoxDecoration(
        color: selected ? AppColors.primary : Colors.white,
        borderRadius: AppRadii.radius(AppRadii.dialog),
        boxShadow: [
          BoxShadow(
            color: (selected ? AppColors.primary : Colors.black).withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration metricTabDecoration({required bool selected, required Color color}) => BoxDecoration(
        color: selected ? color : Colors.white,
        borderRadius: AppRadii.radius(AppSpacing.lg - 2),
        boxShadow: [
          BoxShadow(
            color: (selected ? color : Colors.black).withValues(alpha: 0.1),
            blurRadius: AppSpacing.sm,
            offset: const Offset(0, 3),
          ),
        ],
      );

  static BoxDecoration get metricCardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.radius(AppRadii.dialog),
        boxShadow: AppShadows.primarySoft,
      );

  static BoxDecoration metricIconDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      );

  static BoxDecoration statusBadgeDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.radius(AppSpacing.sm),
      );

  static BoxDecoration get normalRangeLineDecoration => BoxDecoration(
        color: Colors.green.withValues(alpha: 0.4),
        borderRadius: AppRadii.radius(2),
      );

  static BoxDecoration statsRowDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: AppRadii.radius(AppSpacing.lg - 2),
      );

  static BoxDecoration aiSummaryDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: AppRadii.radius(AppSpacing.lg - 2),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      );

  static BoxDecoration get providerBadgeDecoration => BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadii.radius(6),
      );

  static const clinicalTitle = TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold);
  static const clinicalSource = TextStyle(color: Color(0xB3FFFFFF), fontSize: 12);
  static const clinicalStatValue = TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15);
  static const clinicalStatLabel = TextStyle(color: Color(0xB3FFFFFF), fontSize: 11);
  static const metricTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark);
  static const metricDescription = TextStyle(fontSize: 11, color: AppColors.textMuted);
  static const latestTimestamp = TextStyle(fontSize: 9, color: AppColors.textMuted);
  static const normalRangeText = TextStyle(fontSize: 10, color: AppColors.textMuted);
  static const metricNote = TextStyle(fontSize: 11, color: AppColors.textMuted);
  static const statLabel = TextStyle(fontSize: 10, color: AppColors.textMuted);
  static const providerBadgeText = TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.w600);
  static const aiBody = TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.5);
  static const aiMutedText = TextStyle(fontSize: 12, color: AppColors.textMuted);
  static const axisLabel = TextStyle(fontSize: 7, color: Colors.black38);
  static const axisLabelLarge = TextStyle(fontSize: 10, color: Colors.black38);
}

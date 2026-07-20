import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

class InsightsStyles {
  static const sectionMargin = EdgeInsets.only(bottom: AppSpacing.lg);
  static const sectionPadding = EdgeInsets.all(18);
  static const disclaimerMargin = EdgeInsets.only(bottom: AppSpacing.lg);
  static const disclaimerPadding = EdgeInsets.all(AppSpacing.md);
  static const pagePadding = EdgeInsets.fromLTRB(20, 20, 20, 32);
  static const headerPadding = EdgeInsets.all(20);
  static const headerBadgePadding = EdgeInsets.symmetric(horizontal: 12, vertical: 6);
  static const footerPadding = EdgeInsets.all(14);

  static const sectionCardDecoration = BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.dialog)),
    boxShadow: AppShadows.primarySoft,
  );

  static const sectionIconDecoration = BoxDecoration(
    color: AppColors.primarySoft,
    shape: BoxShape.circle,
  );

  static BoxDecoration chipDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadii.radius(AppSpacing.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      );

  static BoxDecoration thresholdChipDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadii.radius(AppRadii.sm + 2),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      );

  static BoxDecoration get disclaimerDecoration => BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: AppRadii.radius(AppSpacing.md),
        border: Border.all(color: Colors.orange.shade300),
      );

  static const headerDecoration = BoxDecoration(
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

  static BoxDecoration get headerIconDecoration => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      );

  static BoxDecoration get headerBadgeDecoration => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: AppRadii.radius(10),
      );

  static BoxDecoration get footerDecoration => BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: AppRadii.radius(AppSpacing.md),
        border: Border.all(color: Colors.orange.shade200),
      );

  static BoxDecoration severityCardDecoration(Color color, Color bgColor) => BoxDecoration(
        color: bgColor,
        borderRadius: AppRadii.radius(AppRadii.dialog),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      );

  static BoxDecoration severityBadgeDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.radius(6),
      );

  static BoxDecoration severityIconDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      );

  static const sectionTitle = TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark);
  static const sectionSubtitle = TextStyle(fontSize: 11, color: AppColors.textMuted);
  static const headerTitle = TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold);
  static const headerSubtitle = TextStyle(color: Color(0xCCFFFFFF), fontSize: 12);
  static const headerBadgeText = TextStyle(color: Colors.white, fontSize: 12);
  static const footerText = TextStyle(fontSize: 12, color: Color(0xFFE65100), height: 1.5);
  static const legendLabel = TextStyle(fontSize: 12, color: AppColors.textMuted);
  static const insightBody = TextStyle(fontSize: 14, color: Color(0xFF444444), height: 1.5);
}

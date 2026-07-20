import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

class DeviceStyles {
  static const bodyPadding = EdgeInsets.fromLTRB(20, 16, 20, 32);
  static const bannerMargin = EdgeInsets.only(bottom: AppSpacing.lg);
  static const bannerPadding = EdgeInsets.all(14);
  static const patientCardMargin = EdgeInsets.only(bottom: AppSpacing.md);
  static const patientCardPadding = EdgeInsets.all(AppSpacing.lg);

  static BoxDecoration get bannerDecoration => BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadii.radius(AppRadii.lg),
        border: Border.all(color: const Color(0x406A1B9A)),
      );

  static const patientCardDecoration = BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.dialog)),
    boxShadow: [
      BoxShadow(
        color: Color(0x126A1B9A),
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration statusIconDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      );

  static BoxDecoration statusChipDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadii.radius(AppSpacing.sm),
      );

  static const simulationIconDecoration = BoxDecoration(
    color: AppColors.primarySoft,
    shape: BoxShape.circle,
  );

  static const sectionLabel = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted);
  static const bannerTitle = TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary);
  static const bannerBody = TextStyle(fontSize: 12, color: AppColors.primary);
  static const patientName = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark);
  static const patientMeta = TextStyle(fontSize: 11, color: AppColors.textMuted);
  static const recordCount = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary);
  static const simulateButton = TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600);
  static const simulationError = TextStyle(color: AppColors.danger, fontSize: 12);
}

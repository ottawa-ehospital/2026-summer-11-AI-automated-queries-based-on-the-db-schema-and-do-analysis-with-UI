import 'package:flutter/material.dart';
import '../../../ui/ui.dart';

class SymptomStyles {
  static const listPadding = EdgeInsets.fromLTRB(20, 20, 20, 32);

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadii.radius(AppRadii.dialog),
        boxShadow: AppShadows.primarySoft,
      );

  static BoxDecoration badgeDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadii.radius(AppRadii.sm),
      );
}

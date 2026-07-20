import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

class GoalStyles {
  static BoxDecoration cardDecoration = const BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.dialog)),
    boxShadow: AppShadows.primarySoft,
  );

  static BoxDecoration iconBadgeDecoration(Color color) => BoxDecoration(
        color: color.withAlpha(31),
        shape: BoxShape.circle,
      );

  static TextStyle progressPercent(Color color) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
      );
}

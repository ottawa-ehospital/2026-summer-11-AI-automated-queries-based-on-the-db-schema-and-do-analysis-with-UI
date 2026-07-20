import 'package:flutter/material.dart';
import '../../../ui/ui.dart';

class ProfileStyles {
  static const headerPadding = EdgeInsets.fromLTRB(24, 32, 24, 40);
  static const infoPadding = EdgeInsets.fromLTRB(20, 24, 20, 32);
  static const rowMargin = EdgeInsets.only(bottom: 12);
  static const rowPadding = EdgeInsets.symmetric(vertical: 16, horizontal: 18);
  static const avatarRadius = 44.0;
  static const rowIconSize = 40.0;

  static BoxDecoration get headerDecoration => const BoxDecoration(
        gradient: AppGradients.primary,
      );

  static BoxDecoration get infoRowDecoration => BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadii.radius(AppRadii.dialog),
        boxShadow: AppShadows.primarySoft,
      );

  static BoxDecoration badgeDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadii.radius(AppRadii.dialog),
      );
}

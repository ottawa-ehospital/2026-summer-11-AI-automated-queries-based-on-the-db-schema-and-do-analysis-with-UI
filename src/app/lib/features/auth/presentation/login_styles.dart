import 'package:flutter/material.dart';
import '../../../ui/ui.dart';

class LoginStyles {
  static const headerPadding = EdgeInsets.fromLTRB(28, 72, 28, 40);
  static const formPadding = EdgeInsets.fromLTRB(24, 32, 24, 24);
  static const heroIconSize = 60.0;

  static const headerRadius = BorderRadius.only(
    bottomLeft: Radius.circular(AppRadii.hero),
    bottomRight: Radius.circular(AppRadii.hero),
  );

  static BoxDecoration get headerDecoration => const BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: headerRadius,
      );

  static BoxDecoration get emailFieldDecoration => BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadii.radius(AppRadii.lg),
        boxShadow: AppShadows.primarySoft,
      );

  static BoxDecoration get errorDecoration => BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: AppRadii.radius(AppRadii.sm),
        border: Border.all(color: Colors.red.shade200),
      );
}

import 'package:flutter/material.dart';
import '../../../ui/ui.dart';

class SettingsStyles {
  static const sliverPadding = EdgeInsets.fromLTRB(20, 8, 20, 32);
  static const sectionHeaderPadding = EdgeInsets.fromLTRB(4, 24, 4, 8);
  static const tileMargin = EdgeInsets.only(bottom: 8);
  static const tileContentPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 4);
  static const iconSize = 38.0;

  static BoxDecoration tileDecoration({Color? color, Color? borderColor}) => BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: AppRadii.radius(AppRadii.xl),
        border: borderColor == null ? null : Border.all(color: borderColor),
        boxShadow: borderColor == null ? AppShadows.primarySoft : null,
      );

  static BoxDecoration iconDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      );
}

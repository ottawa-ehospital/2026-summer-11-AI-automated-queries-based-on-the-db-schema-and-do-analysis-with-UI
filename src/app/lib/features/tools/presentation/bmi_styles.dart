import 'package:flutter/material.dart';
import '../../../ui/ui.dart';

class BmiStyles {
  static const bodyPadding = EdgeInsets.fromLTRB(20, 28, 20, 32);

  static BoxDecoration cardDecoration({Color? accent}) => BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadii.radius(AppRadii.dialog),
        boxShadow: accent == null
            ? AppShadows.primarySoft
            : [
                BoxShadow(
                  color: accent.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
        border: accent == null ? null : Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
      );
}

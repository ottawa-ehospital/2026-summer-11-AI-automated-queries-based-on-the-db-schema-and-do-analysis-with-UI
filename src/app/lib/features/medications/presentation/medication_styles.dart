import 'package:flutter/material.dart';
import '../../../ui/ui.dart';

class MedicationStyles {
  static const listPadding = EdgeInsets.fromLTRB(20, 20, 20, 32);
  static const sheetPadding = EdgeInsets.fromLTRB(24, 24, 24, 24);

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadii.radius(AppRadii.dialog),
        boxShadow: AppShadows.primarySoft,
      );
}

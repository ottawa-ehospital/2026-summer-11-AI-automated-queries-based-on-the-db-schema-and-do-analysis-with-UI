import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

class EmergencyStyles {
  static LinearGradient get headerGradient => LinearGradient(
        colors: [Colors.red.shade700, Colors.red.shade400],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get callGradient => LinearGradient(
        colors: [Colors.red.shade700, Colors.red.shade500],
      );

  static BoxDecoration get warningDecoration => BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: AppRadii.radius(AppRadii.xl),
        border: Border.all(color: Colors.red.shade200),
      );

  static BoxDecoration infoCardDecoration = BoxDecoration(
    color: AppColors.card,
    borderRadius: AppRadii.radius(AppRadii.dialog),
    boxShadow: const [
      BoxShadow(
        color: Color(0x14F44336),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get callButtonDecoration => BoxDecoration(
        gradient: callGradient,
        borderRadius: AppRadii.radius(AppRadii.dialog),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66F44336),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      );

  static TextStyle get sectionLabel => AppTypography.caption.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      );

  static TextStyle get callButtonText => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.5,
      );
}

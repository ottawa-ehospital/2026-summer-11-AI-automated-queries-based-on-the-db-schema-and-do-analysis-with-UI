import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  static const appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const screenTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const body = TextStyle(fontSize: 15, color: AppColors.textBody);
  static const bodyMuted = TextStyle(fontSize: 14, color: AppColors.textMuted);
  static const caption = TextStyle(fontSize: 12, color: AppColors.textMuted);
  static const button = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
}

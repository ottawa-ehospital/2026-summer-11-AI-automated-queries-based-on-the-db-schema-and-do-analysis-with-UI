import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  static const primary = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

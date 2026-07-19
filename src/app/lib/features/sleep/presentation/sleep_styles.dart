import 'package:flutter/material.dart';
import '../../../ui/ui.dart';

class SleepStyles {
  static const page = EdgeInsets.all(16.0);
  static const cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );
  static const cardTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static const metric = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );
  static const metricLabel = TextStyle(
    fontSize: 12,
    color: AppColors.textMuted,
  );
}

import 'package:flutter/material.dart';

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const pageX = 20.0;
  static const pageBottom = 32.0;

  static const page = EdgeInsets.fromLTRB(pageX, xxl, pageX, pageBottom);
  static const dialogTitle = EdgeInsets.fromLTRB(24, 24, 24, 0);
  static const dialogContent = EdgeInsets.fromLTRB(24, 16, 24, 0);
  static const dialogActions = EdgeInsets.fromLTRB(24, 8, 24, 20);
}

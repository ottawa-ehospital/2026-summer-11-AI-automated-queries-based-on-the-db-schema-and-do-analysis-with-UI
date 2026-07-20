import 'package:flutter/material.dart';
import '../../../ui/ui.dart';
import '../presentation/settings_styles.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: SettingsStyles.sectionHeaderPadding,
      child: Text(
        title.toUpperCase(),
        style: AppTypography.caption.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

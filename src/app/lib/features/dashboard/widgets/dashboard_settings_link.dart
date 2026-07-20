import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../presentation/dashboard_styles.dart';

class DashboardSettingsLink extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const DashboardSettingsLink({
    super.key,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.radius(AppRadii.xl),
      child: Container(
        padding: DashboardStyles.settingsPadding,
        decoration: DashboardStyles.settingsLinkDecoration,
        child: Row(
          children: [
            const Icon(Icons.settings_outlined, size: 22, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Text(title, style: DashboardStyles.settingsText),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

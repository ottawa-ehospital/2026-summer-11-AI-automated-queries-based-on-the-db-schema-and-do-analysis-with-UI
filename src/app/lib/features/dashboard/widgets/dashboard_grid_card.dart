import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../presentation/dashboard_styles.dart';

class DashboardGridCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const DashboardGridCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.radius(AppRadii.dialog),
      child: Container(
        decoration: DashboardStyles.gridCardDecoration,
        padding: DashboardStyles.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: DashboardStyles.iconBadgeDecoration,
              child: Icon(icon, size: 28, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: DashboardStyles.gridTitle),
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, textAlign: TextAlign.center, style: DashboardStyles.gridSubtitle),
          ],
        ),
      ),
    );
  }
}

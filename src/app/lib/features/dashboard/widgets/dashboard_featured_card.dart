import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../presentation/dashboard_styles.dart';

class DashboardFeaturedCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const DashboardFeaturedCard({
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
        decoration: DashboardStyles.featuredCardDecoration,
        padding: DashboardStyles.featuredPadding,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: DashboardStyles.featuredIconDecoration,
              child: Icon(icon, size: 28, color: Colors.white),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: DashboardStyles.featuredTitle),
                  const SizedBox(height: 3),
                  Text(subtitle, style: DashboardStyles.featuredSubtitle),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: DashboardStyles.featuredIconDecoration,
              child: const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

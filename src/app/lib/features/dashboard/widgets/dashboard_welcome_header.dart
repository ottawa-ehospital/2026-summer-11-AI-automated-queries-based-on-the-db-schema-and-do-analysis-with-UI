import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../presentation/dashboard_styles.dart';

class DashboardWelcomeHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const DashboardWelcomeHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: DashboardStyles.welcomeTitle),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: AppTypography.bodyMuted),
      ],
    );
  }
}

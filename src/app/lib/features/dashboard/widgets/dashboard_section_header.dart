import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

class DashboardSectionHeader extends StatelessWidget {
  final String title;

  const DashboardSectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(title, style: AppTypography.sectionTitle.copyWith(fontSize: 17)),
    );
  }
}

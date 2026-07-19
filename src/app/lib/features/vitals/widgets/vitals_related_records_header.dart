import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../presentation/vitals_history_styles.dart';

class VitalsRelatedRecordsHeader extends StatelessWidget {
  final String title;

  const VitalsRelatedRecordsHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: VitalsHistoryStyles.relatedIconDecoration,
          child: const Icon(Icons.folder_open_outlined, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title, style: AppTypography.sectionTitle),
      ],
    );
  }
}

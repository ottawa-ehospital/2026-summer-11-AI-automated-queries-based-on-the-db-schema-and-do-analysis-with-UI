import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../presentation/emergency_styles.dart';

class EmergencyWarningBanner extends StatelessWidget {
  final String message;

  const EmergencyWarningBanner({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: EmergencyStyles.warningDecoration,
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, color: Colors.red.shade700, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(message, style: AppTypography.caption.copyWith(fontSize: 13, color: AppColors.textDark))),
        ],
      ),
    );
  }
}

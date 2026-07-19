import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../presentation/emergency_styles.dart';

class EmergencyInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String emptyLabel;
  final VoidCallback onEdit;

  const EmergencyInfoCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.emptyLabel,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: 18),
        decoration: EmergencyStyles.infoCardDecoration,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: Colors.red.shade700),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.red.shade300, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasValue ? value : emptyLabel,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: hasValue ? AppColors.textDark : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, size: 18, color: Colors.red.shade300),
          ],
        ),
      ),
    );
  }
}

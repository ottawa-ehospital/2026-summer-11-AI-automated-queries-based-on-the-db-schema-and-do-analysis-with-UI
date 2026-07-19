import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../presentation/emergency_styles.dart';

class EmergencyCallButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const EmergencyCallButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: EmergencyStyles.callButtonDecoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone_outlined, color: Colors.white, size: 28),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: EmergencyStyles.callButtonText),
          ],
        ),
      ),
    );
  }
}

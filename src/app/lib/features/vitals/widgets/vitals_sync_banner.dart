import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../presentation/vitals_styles.dart';

class VitalsSyncBanner extends StatelessWidget {
  final bool syncing;
  final String? status;
  final String syncingLabel;
  final VoidCallback onDismiss;

  const VitalsSyncBanner({
    super.key,
    required this.syncing,
    required this.status,
    required this.syncingLabel,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (syncing) {
      return Container(
        margin: VitalsStyles.bannerMargin,
        padding: VitalsStyles.syncPadding,
        decoration: VitalsStyles.syncingDecoration,
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(syncingLabel, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final message = status;
    if (message == null) return const SizedBox.shrink();

    final isError = !message.startsWith('Synced');
    final color = isError ? Colors.orange : Colors.green;
    return Container(
      margin: VitalsStyles.bannerMargin,
      padding: VitalsStyles.syncPadding,
      decoration: VitalsStyles.syncResultDecoration(color),
      child: Row(
        children: [
          Icon(isError ? Icons.warning_amber_outlined : Icons.check_circle_outline, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close, size: 16, color: color),
          ),
        ],
      ),
    );
  }
}

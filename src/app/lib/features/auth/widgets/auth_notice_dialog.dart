import 'package:flutter/material.dart';
import '../../../ui/ui.dart';

class AuthNoticeDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String body;
  final String actionLabel;
  final Color actionColor;
  final VoidCallback onAccepted;

  const AuthNoticeDialog({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.actionColor,
    required this.onAccepted,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadii.radius(AppRadii.dialog)),
      titlePadding: AppSpacing.dialogTitle,
      contentPadding: AppSpacing.dialogContent,
      actionsPadding: AppSpacing.dialogActions,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(title, style: AppTypography.sectionTitle)),
        ],
      ),
      content: Text(body, style: AppTypography.bodyMuted.copyWith(height: 1.5)),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onAccepted,
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadii.radius(AppRadii.md)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
            child: Text(actionLabel, style: AppTypography.button.copyWith(fontSize: 15)),
          ),
        ),
      ],
    );
  }
}

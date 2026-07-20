import 'package:flutter/material.dart';
import '../../../ui/ui.dart';
import '../presentation/settings_styles.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color? backgroundColor;
  final Color? borderColor;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor = AppColors.primary,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: SettingsStyles.tileMargin,
      decoration: SettingsStyles.tileDecoration(
        color: backgroundColor,
        borderColor: borderColor,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.radius(AppRadii.xl)),
        contentPadding: SettingsStyles.tileContentPadding,
        leading: Container(
          width: SettingsStyles.iconSize,
          height: SettingsStyles.iconSize,
          decoration: SettingsStyles.iconDecoration(iconColor),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        title: Text(
          title,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: iconColor == AppColors.danger ? iconColor : AppColors.textDark,
          ),
        ),
        subtitle: subtitle == null ? null : Text(subtitle!, style: AppTypography.caption),
        trailing: trailing ??
            (onTap != null ? const Icon(Icons.chevron_right, color: AppColors.textMuted) : null),
        onTap: onTap,
      ),
    );
  }
}

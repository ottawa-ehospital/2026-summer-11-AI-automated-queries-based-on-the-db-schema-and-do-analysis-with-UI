import 'package:flutter/material.dart';
import '../../../ui/ui.dart';
import '../presentation/profile_styles.dart';

class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: ProfileStyles.rowMargin,
      padding: ProfileStyles.rowPadding,
      decoration: ProfileStyles.infoRowDecoration,
      child: Row(
        children: [
          Container(
            width: ProfileStyles.rowIconSize,
            height: ProfileStyles.rowIconSize,
            decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ?? "-",
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

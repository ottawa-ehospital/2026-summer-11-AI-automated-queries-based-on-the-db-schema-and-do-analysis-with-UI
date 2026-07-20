import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../ui/ui.dart';
import '../presentation/profile_styles.dart';
import 'profile_badge.dart';

class ProfileHeader extends StatelessWidget {
  final String? username;
  final String? email;
  final String? role;
  final String? status;

  const ProfileHeader({
    super.key,
    required this.username,
    required this.email,
    required this.role,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      decoration: ProfileStyles.headerDecoration,
      padding: ProfileStyles.headerPadding,
      child: Column(
        children: [
          CircleAvatar(
            radius: ProfileStyles.avatarRadius,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: Text(
              _initials(username),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            username ?? l10n.unknownValue,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            email ?? "",
            style: const TextStyle(fontSize: 14, color: Color(0xCCFFFFFF)),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (role != null) ProfileBadge(label: role!.toUpperCase(), color: Colors.white),
              if (status != null) ...[
                const SizedBox(width: AppSpacing.sm),
                ProfileBadge(
                  label: status!.toUpperCase(),
                  color: status!.toLowerCase() == "active" ? Colors.greenAccent : Colors.orangeAccent,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return "?";
    final parts = name.trim().split(" ");
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

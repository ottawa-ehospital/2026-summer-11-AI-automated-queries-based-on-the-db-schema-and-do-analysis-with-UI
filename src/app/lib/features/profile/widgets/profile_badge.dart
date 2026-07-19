import 'package:flutter/material.dart';
import '../presentation/profile_styles.dart';

class ProfileBadge extends StatelessWidget {
  final String label;
  final Color color;

  const ProfileBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: ProfileStyles.badgeDecoration(color),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

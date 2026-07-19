import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../ui/ui.dart';
import '../presentation/login_styles.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: LoginStyles.headerPadding,
      decoration: LoginStyles.headerDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: LoginStyles.heroIconSize,
            height: LoginStyles.heroIconSize,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.health_and_safety, color: Colors.white, size: 32),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.brandName,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.loginHeaderSubtitle,
            style: const TextStyle(fontSize: 15, color: Color(0xCCFFFFFF)),
          ),
        ],
      ),
    );
  }
}

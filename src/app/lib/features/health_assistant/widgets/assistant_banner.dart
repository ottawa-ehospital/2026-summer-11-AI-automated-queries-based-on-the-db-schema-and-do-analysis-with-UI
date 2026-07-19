import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../presentation/assistant_styles.dart';

class AssistantBanner extends StatelessWidget {
  final String title;
  final String subtitle;

  const AssistantBanner({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AssistantStyles.bannerPadding,
      decoration: AssistantStyles.bannerDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: AssistantStyles.bannerIconDecoration,
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AssistantStyles.bannerTitle),
                Text(subtitle, style: AssistantStyles.bannerSubtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

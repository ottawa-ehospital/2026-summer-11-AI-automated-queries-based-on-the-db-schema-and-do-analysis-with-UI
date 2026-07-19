import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../presentation/assistant_styles.dart';

class AssistantEmptyState extends StatelessWidget {
  final String title;
  final String firstPrompt;
  final String secondPrompt;
  final String disclaimer;
  final bool compact;

  const AssistantEmptyState({
    super.key,
    required this.title,
    required this.firstPrompt,
    required this.secondPrompt,
    required this.disclaimer,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 56.0 : 80.0;
    final iconGlyphSize = compact ? 30.0 : 40.0;
    final largeGap = compact ? AppSpacing.sm : AppSpacing.lg;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.health_and_safety,
              size: iconGlyphSize,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: largeGap),
          Text(title, style: AssistantStyles.emptyTitle),
          if (!compact) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(firstPrompt, style: AssistantStyles.prompt),
            const SizedBox(height: AppSpacing.xs),
            Text(secondPrompt, style: AssistantStyles.prompt),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
              decoration: AssistantStyles.emptyDisclaimerDecoration,
              child: Text(
                disclaimer,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.orange.shade800, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

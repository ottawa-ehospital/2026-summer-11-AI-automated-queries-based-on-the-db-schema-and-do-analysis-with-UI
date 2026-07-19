import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../presentation/assistant_styles.dart';

class AssistantTypingIndicator extends StatelessWidget {
  final String label;

  const AssistantTypingIndicator({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: AssistantStyles.bubbleMargin,
        padding: AssistantStyles.typingPadding,
        decoration: AssistantStyles.typingDecoration,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: AppSpacing.lg,
              height: AppSpacing.lg,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}

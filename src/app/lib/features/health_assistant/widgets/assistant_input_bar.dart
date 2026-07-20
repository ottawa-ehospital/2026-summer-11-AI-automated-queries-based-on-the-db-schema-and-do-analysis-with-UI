import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../presentation/assistant_styles.dart';

class AssistantInputBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isLoading;
  final VoidCallback onSend;

  const AssistantInputBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AssistantStyles.inputDecoration,
      padding: AssistantStyles.inputPadding,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  border: OutlineInputBorder(
                    borderRadius: AppRadii.radius(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                minLines: 1,
                maxLines: 4,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: isLoading ? null : onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

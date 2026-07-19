import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../presentation/assistant_styles.dart';
import 'assistant_result_view.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: AssistantStyles.bubbleMargin,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: AssistantStyles.bubblePadding,
        decoration: AssistantStyles.messageBubbleDecoration(isUser: isUser),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: AssistantStyles.messageText.copyWith(
                color: isUser ? Colors.white : const Color(0xFF222222),
              ),
            ),
            if (!isUser)
              ...message.results.map(
                (result) => AssistantResultView(result: result),
              ),
          ],
        ),
      ),
    );
  }
}

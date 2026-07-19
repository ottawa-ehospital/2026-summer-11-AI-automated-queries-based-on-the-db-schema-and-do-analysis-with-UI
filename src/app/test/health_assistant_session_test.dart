import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_health_app/features/health_assistant/data/chat_session_store.dart';
import 'package:smart_health_app/features/health_assistant/models/chat_message.dart';
import 'package:smart_health_app/features/health_assistant/models/chat_session.dart';

void main() {
  test('chat session serializes messages and title metadata', () {
    final session = ChatSession.blank().copyWith(
      title: ChatSession.inferTitle('What does my sleep trend mean?'),
      messages: [
        ChatMessage(role: 'user', content: 'What does my sleep trend mean?'),
        ChatMessage(role: 'assistant', content: 'Your sleep was steady.'),
      ],
    );

    final decoded = ChatSession.fromJson(session.toJson());

    expect(decoded.id, session.id);
    expect(decoded.title, 'What does my sleep trend mean');
    expect(decoded.messages.length, 2);
    expect(decoded.messages.first.isUser, isTrue);
  });

  test(
    'session title inference cleans whitespace and truncates long messages',
    () {
      final title = ChatSession.inferTitle(
        '   Can you explain why my heart rate was high after exercise yesterday?   ',
      );

      expect(title.endsWith('?'), isFalse);
      expect(title.length, lessThanOrEqualTo(48));
      expect(title, startsWith('Can you explain'));
    },
  );

  test('recentMessagesForContext returns only latest ten messages', () {
    final session = ChatSession.blank().copyWith(
      messages: [
        for (var index = 0; index < 12; index++)
          ChatMessage(
            role: index.isEven ? 'user' : 'assistant',
            content: 'message $index',
          ),
      ],
    );

    final history = session.recentMessagesForContext();

    expect(history.length, 10);
    expect(history.first.content, 'message 2');
    expect(history.last.content, 'message 11');
  });

  test('chat session store persists sessions ordered by update time', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ChatSessionStore();
    final older = ChatSession(
      id: 'older',
      title: 'Older',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      messages: [ChatMessage(role: 'user', content: 'Older chat')],
    );
    final newer = ChatSession(
      id: 'newer',
      title: 'Newer',
      createdAt: DateTime(2026, 1, 2),
      updatedAt: DateTime(2026, 1, 2),
      messages: [ChatMessage(role: 'user', content: 'Newer chat')],
    );

    await store.upsertSession(older);
    await store.upsertSession(newer);

    final sessions = await store.loadSessions();
    expect(sessions.map((session) => session.title), ['Newer', 'Older']);
  });
}

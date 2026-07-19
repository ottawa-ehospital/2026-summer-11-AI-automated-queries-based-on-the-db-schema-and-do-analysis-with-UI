import 'chat_message.dart';

class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  factory ChatSession.blank() {
    final now = DateTime.now();
    return ChatSession(
      id: 'session_${now.microsecondsSinceEpoch}',
      title: '',
      createdAt: now,
      updatedAt: now,
      messages: const [],
    );
  }

  ChatSession copyWith({
    String? title,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
  }) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }

  String get displayTitle {
    if (title.trim().isNotEmpty) return title;
    return messages.isEmpty ? 'New chat' : inferTitle(messages.first.content);
  }

  String get preview {
    if (messages.isEmpty) return '';
    final content = messages.last.content
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (content.length <= 72) return content;
    return '${content.substring(0, 69).trimRight()}...';
  }

  List<ChatMessage> recentMessagesForContext({int limit = 10}) {
    final cleanMessages = messages
        .where((message) => message.content.trim().isNotEmpty)
        .toList();
    if (cleanMessages.length <= limit) return cleanMessages;
    return cleanMessages.sublist(cleanMessages.length - limit);
  }

  static String inferTitle(String firstUserMessage) {
    var cleaned = firstUserMessage.replaceAll(RegExp(r'\s+'), ' ').trim();
    cleaned = cleaned.replaceAll(RegExp(r'[?!.。！？]+$'), '').trim();
    if (cleaned.isEmpty) return 'New chat';
    if (cleaned.length <= 48) return cleaned;
    return '${cleaned.substring(0, 45).trimRight()}...';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'messages': messages.map((message) => message.toJson()).toList(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    return ChatSession(
      id:
          json['id']?.toString() ??
          'session_${DateTime.now().microsecondsSinceEpoch}',
      title: json['title']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      messages: rawMessages is List
          ? rawMessages
                .whereType<Map>()
                .map(
                  (item) =>
                      ChatMessage.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : <ChatMessage>[],
    );
  }
}

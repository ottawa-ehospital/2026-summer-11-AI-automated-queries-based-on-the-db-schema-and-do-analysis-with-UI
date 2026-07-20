import '../../../data/models/assistant_models.dart';

class ChatMessage {
  final String role;
  final String content;
  final DateTime createdAt;
  final List<AssistantResult> results;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? createdAt,
    List<AssistantResult>? results,
  }) : createdAt = createdAt ?? DateTime.now(),
       results = results ?? const [];

  bool get isUser => role == 'user';

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    if (results.isNotEmpty)
      'results': results.map((result) => result.toJson()).toList(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];
    return ChatMessage(
      role: json['role']?.toString() ?? 'assistant',
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      results: rawResults is List
          ? rawResults
                .whereType<Map>()
                .map(
                  (item) =>
                      AssistantResult.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }
}

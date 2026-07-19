import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_session.dart';

class ChatSessionStore {
  static const _sessionsKey = 'health_assistant_chat_sessions_v1';

  Future<List<ChatSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionsKey);
    if (raw == null || raw.trim().isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    final sessions = decoded
        .whereType<Map>()
        .map((item) => ChatSession.fromJson(Map<String, dynamic>.from(item)))
        .where((session) => session.messages.isNotEmpty)
        .toList();
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  Future<void> upsertSession(ChatSession session) async {
    if (session.messages.isEmpty) return;
    final sessions = await loadSessions();
    final next = [
      session,
      ...sessions.where((existing) => existing.id != session.id),
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _saveSessions(next);
  }

  Future<void> _saveSessions(List<ChatSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      sessions.map((session) => session.toJson()).toList(),
    );
    await prefs.setString(_sessionsKey, encoded);
  }
}

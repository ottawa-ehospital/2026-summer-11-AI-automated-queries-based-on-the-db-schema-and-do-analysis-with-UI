import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/api_config.dart';
import '../data/models/assistant_models.dart';
import 'backend_api_service.dart';
import 'ollama_service.dart';

class AiService {
  static Future<String> generate({
    required String prompt,
    String? systemPrompt,
    String? patientId,
    List<AssistantConversationMessage> history = const [],
  }) async {
    switch (ApiConfig.aiProvider.toLowerCase()) {
      case 'backend':
        if (patientId == null || patientId.trim().isEmpty) {
          throw StateError('Missing patient id for backend AI request.');
        }
        final response = await BackendApiService.assistantChat(
          patientId: patientId,
          message: prompt,
          history: history,
        );
        return response.reply;
      case 'gemini':
        return _generateWithGemini(
          prompt: _promptWithHistory(prompt, history),
          systemPrompt: systemPrompt,
        );
      case 'ollama':
        return OllamaService.generate(
          prompt: _promptWithHistory(prompt, history),
          systemPrompt: systemPrompt,
        );
      default:
        throw StateError(
          'Unsupported AI_PROVIDER "${ApiConfig.aiProvider}". '
          'Use "backend", "ollama", or "gemini".',
        );
    }
  }

  static Future<AssistantChatReply> generateAssistantReply({
    required String prompt,
    String? systemPrompt,
    String? patientId,
    List<AssistantConversationMessage> history = const [],
  }) async {
    switch (ApiConfig.aiProvider.toLowerCase()) {
      case 'backend':
        if (patientId == null || patientId.trim().isEmpty) {
          throw StateError('Missing patient id for backend AI request.');
        }
        return BackendApiService.assistantChat(
          patientId: patientId,
          message: prompt,
          history: history,
        );
      default:
        final reply = await generate(
          prompt: prompt,
          systemPrompt: systemPrompt,
          patientId: patientId,
          history: history,
        );
        return AssistantChatReply(
          reply: reply,
          results: [AssistantTextResult(content: reply)],
        );
    }
  }

  static String _promptWithHistory(
    String prompt,
    List<AssistantConversationMessage> history,
  ) {
    if (history.isEmpty) return prompt;
    final buffer = StringBuffer('Recent conversation:\n');
    for (final item in history.take(10)) {
      buffer.writeln('${item.role}: ${item.content}');
    }
    buffer
      ..writeln()
      ..writeln('Current user message:')
      ..write(prompt);
    return buffer.toString();
  }

  static Future<String> _generateWithGemini({
    required String prompt,
    String? systemPrompt,
  }) async {
    ApiConfig.requireGeminiConfig();

    final model = GenerativeModel(
      model: ApiConfig.geminiModel,
      apiKey: ApiConfig.geminiApiKey,
      systemInstruction: systemPrompt == null || systemPrompt.trim().isEmpty
          ? null
          : Content.system(systemPrompt),
    );
    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text?.trim();
    if (text == null || text.isEmpty) {
      throw Exception('Gemini returned an empty response.');
    }
    return text;
  }
}

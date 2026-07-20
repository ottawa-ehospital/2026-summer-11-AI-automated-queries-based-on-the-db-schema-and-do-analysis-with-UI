import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class OllamaService {
  static Future<String> generate({
    required String prompt,
    String? systemPrompt,
  }) async {
    final uri = Uri.parse('${ApiConfig.ollamaBaseUrl}/api/generate');
    final response = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': ApiConfig.ollamaModel,
            'prompt': prompt,
            if (systemPrompt != null && systemPrompt.trim().isNotEmpty)
              'system': systemPrompt,
            'stream': false,
          }),
        )
        .timeout(const Duration(seconds: 90));

    if (response.statusCode != 200) {
      throw Exception(
        'Ollama request failed (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final text = body['response']?.toString().trim();
    if (text == null || text.isEmpty) {
      throw Exception('Ollama returned an empty response.');
    }
    return text;
  }
}

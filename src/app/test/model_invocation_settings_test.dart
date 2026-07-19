import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_health_app/core/network/api_client.dart';
import 'package:smart_health_app/data/models/model_invocation_settings.dart';
import 'package:smart_health_app/data/repositories/assistant_repository.dart';
import 'package:smart_health_app/data/repositories/model_invocation_settings_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('model invocation settings serialize to backend request shape', () {
    const settings = ModelInvocationSettings(
      providerKey: ModelInvocationSettings.providerDirectLocal,
      modelProvider: 'ollama',
      modelName: 'llama3.1:8b',
      baseUrl: 'http://127.0.0.1:11434',
      useGraphFlow: false,
    );

    expect(settings.toJson(), {
      'provider_key': 'direct_local',
      'model_provider': 'ollama',
      'model_name': 'llama3.1:8b',
      'base_url': 'http://127.0.0.1:11434',
      'use_graph_flow': false,
    });
    expect(ModelInvocationSettings.fromJson(settings.toJson()).summary, settings.summary);
  });

  test('model invocation settings store persists non-secret settings', () async {
    final store = ModelInvocationSettingsStore();
    const settings = ModelInvocationSettings(
      providerKey: ModelInvocationSettings.providerDirectGemini,
      modelProvider: 'gemini',
      modelName: 'gemini-1.5-flash',
      baseUrl: '',
      useGraphFlow: false,
    );

    await store.save(settings);

    final saved = await store.loadSaved();
    expect(saved?.providerKey, ModelInvocationSettings.providerDirectGemini);
    expect(saved?.modelName, 'gemini-1.5-flash');
    expect(saved?.toJson().containsKey('api_key'), isFalse);
  });

  test('assistant repository includes saved invocation settings', () async {
    final store = ModelInvocationSettingsStore();
    await store.save(
      const ModelInvocationSettings(
        providerKey: ModelInvocationSettings.providerDirectLocal,
        modelProvider: 'ollama',
        modelName: 'llama3.1:8b',
        baseUrl: 'http://127.0.0.1:11434',
        useGraphFlow: false,
      ),
    );
    late Map<String, dynamic> body;
    final repository = AssistantRepository(
      client: ApiClient(
        baseUrl: 'https://example.test',
        client: MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'reply': 'ok',
              'results': [
                {'type': 'text', 'content': 'ok'},
              ],
            }),
            200,
          );
        }),
      ),
      modelInvocationStore: store,
    );

    await repository.chat(patientId: '20', message: 'hello');

    expect(body['model_invocation'], isA<Map<String, dynamic>>());
    expect(body['model_invocation']['provider_key'], 'direct_local');
  });

  test('assistant repository omits invocation settings when none saved', () async {
    late Map<String, dynamic> body;
    final repository = AssistantRepository(
      client: ApiClient(
        baseUrl: 'https://example.test',
        client: MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'reply': 'ok',
              'results': [
                {'type': 'text', 'content': 'ok'},
              ],
            }),
            200,
          );
        }),
      ),
    );

    await repository.chat(patientId: '20', message: 'hello');

    expect(body.containsKey('model_invocation'), isFalse);
  });
}

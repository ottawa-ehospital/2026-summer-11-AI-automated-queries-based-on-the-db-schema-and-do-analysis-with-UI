import 'package:flutter/foundation.dart';

import '../../config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/assistant_models.dart';
import 'model_invocation_settings_store.dart';

class AssistantRepository {
  final ApiClient _client;
  final ModelInvocationSettingsStore _modelInvocationStore;

  AssistantRepository({
    ApiClient? client,
    ModelInvocationSettingsStore? modelInvocationStore,
  }) : _client = client ?? ApiClient(baseUrl: ApiConfig.backendBaseUrl),
       _modelInvocationStore =
           modelInvocationStore ?? ModelInvocationSettingsStore();

  Future<AssistantChatReply> chat({
    required String patientId,
    required String message,
    List<AssistantConversationMessage> history = const [],
  }) async {
    // Assistant endpoints are backend-mediated so model credentials and prompt
    // orchestration stay out of the Flutter client.
    debugPrint(
      '[AssistantRepository] POST ${ApiConfig.backendBaseUrl}/assistant/chat '
      'patient_id=$patientId',
    );
    final body = {
      'patient_id': patientId,
      'message': message,
      if (history.isNotEmpty)
        'history': history.map((item) => item.toJson()).toList(),
    };
    final modelInvocation = await _savedModelInvocationJson();
    if (modelInvocation != null) {
      body['model_invocation'] = modelInvocation;
    }
    final decoded = await _client.postJson('/assistant/chat', body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Backend returned an unexpected response.');
    }
    final reply = AssistantChatReply.fromJson(decoded);
    debugPrint(
      '[AssistantRepository] assistant results='
      '${reply.results.map((result) => result.type).join(',')}',
    );
    return reply;
  }

  Future<String> vitalsSummary({
    required String patientId,
    required String metric,
    required String unit,
    required String healthyRange,
    double? latest,
    double? average,
    double? peak,
    int zeroCount = 0,
    int totalCount = 0,
    String? clinicalNote,
  }) async {
    // Keep the UI contract small: screens pass metric facts, backend decides
    // how to prompt the configured local or remote model.
    final body = {
      'patient_id': patientId,
      'metric': metric,
      'unit': unit,
      'healthy_range': healthyRange,
      'latest': latest,
      'average': average,
      'peak': peak,
      'zero_count': zeroCount,
      'total_count': totalCount,
      'clinical_note': clinicalNote,
    };
    final modelInvocation = await _savedModelInvocationJson();
    if (modelInvocation != null) {
      body['model_invocation'] = modelInvocation;
    }
    final decoded = await _client.postJson('/assistant/vitals-summary', body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Backend returned an unexpected response.');
    }
    return decoded['summary']?.toString() ?? '';
  }

  Future<Map<String, String>> trendInsights({
    required String patientId,
    required Map<String, double> steps,
    required Map<String, double> calories,
    required Map<String, double> heartRate,
    required Map<String, double> sleep,
  }) async {
    // The backend returns a label-to-sentence map; normalize all keys/values to
    // strings so chart screens do not need response-shape guards.
    final body = {
      'patient_id': patientId,
      'steps': steps,
      'calories': calories,
      'heart_rate': heartRate,
      'sleep': sleep,
    };
    final modelInvocation = await _savedModelInvocationJson();
    if (modelInvocation != null) {
      body['model_invocation'] = modelInvocation;
    }
    final decoded = await _client.postJson('/assistant/trend-insights', body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Backend returned an unexpected response.');
    }
    final raw = decoded['insights'];
    if (raw is! Map) return {};
    return raw.map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  Future<String> stressAnalysis({required String patientId}) async {
    final body = <String, dynamic>{'patient_id': patientId};
    final modelInvocation = await _savedModelInvocationJson();
    if (modelInvocation != null) {
      body['model_invocation'] = modelInvocation;
    }
    final decoded = await _client.postJson('/assistant/stress-analysis', body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Backend returned an unexpected response.');
    }
    return decoded['analysis']?.toString() ?? '';
  }

  Future<Map<String, dynamic>?> _savedModelInvocationJson() async {
    final settings = await _modelInvocationStore.loadSaved();
    return settings?.toJson();
  }
}

import '../../config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/health_alert_models.dart';
import 'model_invocation_settings_store.dart';

abstract class HealthAlertAnalysisClient {
  Future<HealthAlertDecision> analyze(HealthAlertEvent event);
}

class HealthAlertRepository implements HealthAlertAnalysisClient {
  final ApiClient _client;
  final ModelInvocationSettingsStore _modelInvocationStore;

  HealthAlertRepository({
    ApiClient? client,
    ModelInvocationSettingsStore? modelInvocationStore,
  }) : _client = client ?? ApiClient(baseUrl: ApiConfig.backendBaseUrl),
       _modelInvocationStore =
           modelInvocationStore ?? ModelInvocationSettingsStore();

  @override
  Future<HealthAlertDecision> analyze(HealthAlertEvent event) async {
    final error = event.validate();
    if (error != null) throw ApiException(error);

    final body = event.toJson();
    final modelInvocation = await _savedModelInvocationJson();
    if (modelInvocation != null) {
      body['model_invocation'] = modelInvocation;
    }
    final decoded = await _client.postJson(
      '/assistant/health-alert/analyze',
      body,
    );
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Backend returned an unexpected response.');
    }
    return HealthAlertDecision.fromJson(decoded);
  }

  Future<Map<String, dynamic>?> _savedModelInvocationJson() async {
    final settings = await _modelInvocationStore.loadSaved();
    return settings?.toJson();
  }
}

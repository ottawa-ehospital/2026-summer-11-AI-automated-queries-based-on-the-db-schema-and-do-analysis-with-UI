import '../../config/api_config.dart';

class ModelInvocationSettings {
  static const providerWearableLangGraph = 'wearable_langgraph';
  static const providerDirectLocal = 'direct_local';
  static const providerDirectGemini = 'direct_gemini';

  final String providerKey;
  final String modelProvider;
  final String modelName;
  final String baseUrl;
  final bool useGraphFlow;

  const ModelInvocationSettings({
    required this.providerKey,
    required this.modelProvider,
    required this.modelName,
    required this.baseUrl,
    required this.useGraphFlow,
  });

  factory ModelInvocationSettings.defaults() {
    return const ModelInvocationSettings(
      providerKey: providerWearableLangGraph,
      modelProvider: ApiConfig.defaultModelProvider,
      modelName: ApiConfig.defaultModelName,
      baseUrl: ApiConfig.defaultModelBaseUrl,
      useGraphFlow: true,
    );
  }

  factory ModelInvocationSettings.fromJson(Map<String, dynamic> json) {
    final defaults = ModelInvocationSettings.defaults();
    return ModelInvocationSettings(
      providerKey: _readString(json['provider_key'], defaults.providerKey),
      modelProvider: _readString(json['model_provider'], defaults.modelProvider),
      modelName: _readString(json['model_name'], defaults.modelName),
      baseUrl: _readString(json['base_url'], defaults.baseUrl),
      useGraphFlow: json['use_graph_flow'] is bool
          ? json['use_graph_flow'] as bool
          : defaults.useGraphFlow,
    );
  }

  ModelInvocationSettings copyWith({
    String? providerKey,
    String? modelProvider,
    String? modelName,
    String? baseUrl,
    bool? useGraphFlow,
  }) {
    return ModelInvocationSettings(
      providerKey: providerKey ?? this.providerKey,
      modelProvider: modelProvider ?? this.modelProvider,
      modelName: modelName ?? this.modelName,
      baseUrl: baseUrl ?? this.baseUrl,
      useGraphFlow: useGraphFlow ?? this.useGraphFlow,
    );
  }

  Map<String, dynamic> toJson() => {
    'provider_key': providerKey,
    'model_provider': modelProvider,
    'model_name': modelName,
    'base_url': baseUrl,
    'use_graph_flow': useGraphFlow,
  };

  String get summary {
    final flow = useGraphFlow ? 'graph' : 'direct';
    return '$providerKey / $modelProvider:$modelName ($flow)';
  }

  static String _readString(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}

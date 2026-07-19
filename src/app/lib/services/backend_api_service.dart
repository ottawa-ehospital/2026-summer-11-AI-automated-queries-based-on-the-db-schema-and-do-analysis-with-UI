import '../data/repositories/assistant_repository.dart';
import '../data/models/assistant_models.dart';

export '../core/network/api_exception.dart';

// Compatibility facade for screens that still call the old static service API.
// New code should prefer AssistantRepository directly.
class BackendApiService {
  static final AssistantRepository _repository = AssistantRepository();

  static Future<AssistantChatReply> assistantChat({
    required String patientId,
    required String message,
    List<AssistantConversationMessage> history = const [],
  }) {
    return _repository.chat(
      patientId: patientId,
      message: message,
      history: history,
    );
  }

  static Future<String> vitalsSummary({
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
  }) {
    return _repository.vitalsSummary(
      patientId: patientId,
      metric: metric,
      unit: unit,
      healthyRange: healthyRange,
      latest: latest,
      average: average,
      peak: peak,
      zeroCount: zeroCount,
      totalCount: totalCount,
      clinicalNote: clinicalNote,
    );
  }

  static Future<Map<String, String>> trendInsights({
    required String patientId,
    required Map<String, double> steps,
    required Map<String, double> calories,
    required Map<String, double> heartRate,
    required Map<String, double> sleep,
  }) {
    return _repository.trendInsights(
      patientId: patientId,
      steps: steps,
      calories: calories,
      heartRate: heartRate,
      sleep: sleep,
    );
  }

  static Future<String> stressAnalysis({required String patientId}) {
    return _repository.stressAnalysis(patientId: patientId);
  }
}

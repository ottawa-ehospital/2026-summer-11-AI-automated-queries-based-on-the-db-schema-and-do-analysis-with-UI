import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../config/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../models/nutrition_monitor_models.dart';

class NutritionMonitorRepository {
  NutritionMonitorRepository({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? ApiConfig.backendBaseUrl,
      _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  void close() {
    _client.close();
  }

  Uri _uri(String path, {Map<String, String>? queryParameters}) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse(
      '$normalizedBase$normalizedPath',
    ).replace(queryParameters: queryParameters);
  }

  Future<NutritionHealth> fetchHealth() async {
    final response = await _client.get(_uri('/nutrition-monitor/health'));
    _throwIfError(response, fallback: 'Nutrition Monitor is unavailable');
    return NutritionHealth.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<NutritionAnalysisResult> analyzeImage({
    required PickedMealImage image,
    required int patientId,
    String? hint,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/nutrition-monitor/analyze-image'),
    );
    if (image.hasPath) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          image.path!,
          filename: image.name,
        ),
      );
    } else if (image.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          image.bytes!,
          filename: image.name,
          contentType: null,
        ),
      );
    } else {
      throw const ApiException('Meal image is not available.');
    }
    request.fields['patientId'] = patientId.toString();
    if (hint != null && hint.trim().isNotEmpty) {
      request.fields['hint'] = hint.trim();
    }

    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    _throwIfError(response, fallback: 'Food image analysis failed');
    return NutritionAnalysisResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> logMeal(NutritionAnalysisResult analysis) async {
    final response = await _client.post(
      _uri('/nutrition-monitor/meals'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(analysis.toMealJson()),
    );
    _throwIfError(response, fallback: 'Could not log meal');
  }

  Future<List<MealLogRecord>> fetchMealHistory(int patientId) async {
    final response = await _client.get(
      _uri(
        '/nutrition-monitor/meals',
        queryParameters: {'patientId': '$patientId'},
      ),
    );
    _throwIfError(response, fallback: 'Could not load meal history');
    return (jsonDecode(response.body) as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(MealLogRecord.fromJson)
        .toList();
  }

  Future<DailySummary> fetchDailySummary(int patientId) async {
    final response = await _client.get(
      _uri(
        '/nutrition-monitor/summary/daily',
        queryParameters: {'patientId': '$patientId'},
      ),
    );
    _throwIfError(response, fallback: 'Could not load daily summary');
    return DailySummary.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<NutritionGoals> fetchGoals(int patientId) async {
    final response = await _client.get(
      _uri(
        '/nutrition-monitor/goals',
        queryParameters: {'patientId': '$patientId'},
      ),
    );
    _throwIfError(response, fallback: 'Could not load nutrition goals');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return NutritionGoals.fromJson(
      (data['goals'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  void _throwIfError(http.Response response, {required String fallback}) {
    if (response.statusCode < 400) return;
    var message = fallback;
    try {
      final decoded = jsonDecode(response.body);
      final detail = decoded is Map ? decoded['detail'] : null;
      if (detail is Map &&
          detail['code'] == 'nutrition_image_model_unsupported') {
        message =
            detail['message']?.toString() ??
            'The current model does not support food image analysis.';
      } else if (detail != null) {
        message = detail.toString();
      }
    } catch (_) {
      if (response.body.trim().isNotEmpty) {
        message = response.body.trim();
      }
    }
    throw ApiException(message, statusCode: response.statusCode);
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_health_app/core/network/api_exception.dart';
import 'package:smart_health_app/features/nutrition_monitor/data/nutrition_monitor_repository.dart';
import 'package:smart_health_app/features/nutrition_monitor/models/nutrition_monitor_models.dart';

void main() {
  test('fetchHealth reads image model capabilities', () async {
    late Uri captured;
    final repository = NutritionMonitorRepository(
      baseUrl: 'https://example.test',
      client: MockClient((request) async {
        captured = request.url;
        return http.Response(
          jsonEncode({
            'imageAnalysis': {
              'supportsImageInput': true,
              'provider': 'openai',
              'model': 'gpt-4o',
            },
          }),
          200,
        );
      }),
    );

    final health = await repository.fetchHealth();

    expect(captured.path, '/nutrition-monitor/health');
    expect(health.imageAnalysis.supportsImageInput, isTrue);
    expect(health.imageAnalysis.model, 'gpt-4o');
  });

  test('analyzeImage sends multipart image, patient id, and hint', () async {
    http.BaseRequest? capturedRequest;
    String capturedBody = '';
    final repository = NutritionMonitorRepository(
      baseUrl: 'https://example.test/',
      client: MockClient.streaming((request, bodyStream) async {
        capturedRequest = request;
        capturedBody = utf8.decode(await bodyStream.toBytes());
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              jsonEncode({
                'patientId': 42,
                'dishName': 'Grilled salmon',
                'portionSize': '1 plate',
                'ingredients': ['salmon', 'rice'],
                'nutritionalBreakdown': {
                  'totalCalories': 520,
                  'totalProtein': 38,
                  'totalFat': 22,
                  'totalCarbs': 40,
                  'totalSodium': 480,
                  'totalSugar': 4,
                },
                'insights': {
                  'risks': [],
                  'warnings': [],
                  'positives': ['High protein'],
                },
                'finalVerdict': 'good',
                'finalVerdictReasoning': 'Balanced meal.',
                'isFood': true,
                'modelCapabilities': {
                  'supportsImageInput': true,
                  'provider': 'openai',
                  'model': 'gpt-4o',
                },
              }),
            ),
          ),
          200,
        );
      }),
    );

    final result = await repository.analyzeImage(
      image: PickedMealImage(
        name: 'meal.jpg',
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
      patientId: 42,
      hint: 'low salt',
    );

    expect(result.dishName, 'Grilled salmon');
    expect(capturedRequest?.method, 'POST');
    expect(capturedRequest?.url.path, '/nutrition-monitor/analyze-image');
    expect(capturedBody, contains('name="file"'));
    expect(capturedBody, contains('filename="meal.jpg"'));
    expect(capturedBody, contains('name="patientId"'));
    expect(capturedBody, contains('42'));
    expect(capturedBody, contains('name="hint"'));
    expect(capturedBody, contains('low salt'));
    expect(capturedBody, isNot(contains('/api/')));
  });

  test('unsupported image model error is mapped to ApiException message', () {
    final repository = NutritionMonitorRepository(
      baseUrl: 'https://example.test',
      client: MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              jsonEncode({
                'detail': {
                  'code': 'nutrition_image_model_unsupported',
                  'message': 'Current model cannot analyze images.',
                  'provider': 'ollama',
                  'model': 'llama3.2',
                },
              }),
            ),
          ),
          409,
        );
      }),
    );

    expect(
      () => repository.analyzeImage(
        image: PickedMealImage(
          name: 'meal.jpg',
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
        patientId: 42,
      ),
      throwsA(
        isA<ApiException>()
            .having(
              (error) => error.message,
              'message',
              'Current model cannot analyze images.',
            )
            .having((error) => error.statusCode, 'statusCode', 409),
      ),
    );
  });

  test('logMeal posts patient-scoped meal without raw image data', () async {
    late http.Request captured;
    final repository = NutritionMonitorRepository(
      baseUrl: 'https://example.test',
      client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'ok': true}), 200);
      }),
    );

    await repository.logMeal(
      NutritionAnalysisResult(
        patientId: 42,
        dishName: 'Oatmeal',
        portionSize: '1 bowl',
        ingredients: const ['oats'],
        nutritionalBreakdown: const NutritionalBreakdown(
          totalCalories: 280,
          totalProtein: 10,
          totalFat: 6,
          totalCarbs: 48,
          totalSodium: 120,
          totalSugar: 8,
        ),
        insights: const PersonalizedInsights(
          risks: [],
          warnings: [],
          positives: ['High fiber'],
        ),
        finalVerdict: 'good',
        finalVerdictReasoning: 'Fits goals.',
        isFood: true,
        modelCapabilities: const NutritionModelCapabilities(
          supportsImageInput: true,
          provider: 'openai',
          model: 'gpt-4o',
        ),
      ),
    );

    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(captured.url.path, '/nutrition-monitor/meals');
    expect(body['patientId'], 42);
    expect(body['dishName'], 'Oatmeal');
    expect(body.containsKey('imageBytes'), isFalse);
    expect(body.containsKey('imageStoragePath'), isFalse);
  });
}

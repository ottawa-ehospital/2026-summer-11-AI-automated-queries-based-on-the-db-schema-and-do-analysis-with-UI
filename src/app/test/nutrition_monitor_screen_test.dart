import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_health_app/features/nutrition_monitor/data/nutrition_monitor_repository.dart';
import 'package:smart_health_app/features/nutrition_monitor/models/nutrition_monitor_models.dart';
import 'package:smart_health_app/features/nutrition_monitor/nutrition_monitor.dart';
import 'package:smart_health_app/ui/app_theme.dart';

class _FakeNutritionMonitorRepository extends NutritionMonitorRepository {
  _FakeNutritionMonitorRepository({required this.supportsImageInput})
    : super(baseUrl: 'https://example.test');

  final bool supportsImageInput;
  int fetchGoalsCount = 0;

  @override
  Future<NutritionHealth> fetchHealth() async {
    return NutritionHealth(
      imageAnalysis: NutritionModelCapabilities(
        supportsImageInput: supportsImageInput,
        provider: 'ollama',
        model: supportsImageInput ? 'llava' : 'llama3.2',
        reason: supportsImageInput ? null : 'Text-only model',
      ),
    );
  }

  @override
  Future<List<MealLogRecord>> fetchMealHistory(int patientId) async => const [];

  @override
  Future<DailySummary> fetchDailySummary(int patientId) async {
    return DailySummary.empty(patientId);
  }

  @override
  Future<NutritionGoals> fetchGoals(int patientId) async {
    fetchGoalsCount += 1;
    return const NutritionGoals(
      calories: 1900,
      protein: 100,
      carbs: 210,
      fat: 60,
    );
  }
}

void main() {
  testWidgets('nutrition monitor requires patient context', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: NutritionMonitorScreen(
            repository: _FakeNutritionMonitorRepository(
              supportsImageInput: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Patient context required'), findsOneWidget);
    expect(
      find.text('Please log in before using Nutrition Monitor.'),
      findsOneWidget,
    );
  });

  testWidgets('unsupported image model disables meal analysis', (tester) async {
    SharedPreferences.setMockInitialValues({'patient_id': 42});

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: NutritionMonitorScreen(
            repository: _FakeNutritionMonitorRepository(
              supportsImageInput: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nutrition Monitor'), findsOneWidget);
    expect(find.textContaining('Image analysis unavailable'), findsOneWidget);
    expect(
      find.textContaining('does not support food image analysis'),
      findsOneWidget,
    );

    final analyzeButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Analyze meal'),
    );
    expect(analyzeButton.onPressed, isNull);
  });

  testWidgets('nutrition goals prefer patient-scoped local values', (
    tester,
  ) async {
    final repository = _FakeNutritionMonitorRepository(
      supportsImageInput: true,
    );
    SharedPreferences.setMockInitialValues({
      'patient_id': 42,
      'nutrition_goals_42': ['1800', '90', '200', '55'],
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(body: NutritionMonitorScreen(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.fetchGoalsCount, 0);
    expect(find.text('0 / 1800 kcal'), findsOneWidget);
    expect(find.text('0 / 90 g'), findsOneWidget);
  });
}

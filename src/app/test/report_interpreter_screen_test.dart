import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_health_app/features/report_interpreter/data/report_interpreter_repository.dart';
import 'package:smart_health_app/features/report_interpreter/models/report_interpreter_models.dart';
import 'package:smart_health_app/features/report_interpreter/report_interpreter.dart';
import 'package:smart_health_app/ui/app_theme.dart';

class _FakeReportInterpreterRepository extends ReportInterpreterRepository {
  _FakeReportInterpreterRepository() : super(baseUrl: 'https://example.test');

  @override
  Future<List<TestType>> fetchTestTypes() async {
    return const [TestType(id: 'blood', name: 'Blood Work')];
  }

  @override
  Future<List<String>> fetchDates({
    required String testType,
    required String patientId,
  }) async {
    return ['2026-02-01'];
  }

  @override
  Future<PickedReport> fetchSavedRecord({
    required String type,
    required String date,
    required String patientId,
  }) async {
    return PickedReport(
      name: '$type-$date.txt',
      bytes: Uint8List.fromList('Glucose 150'.codeUnits),
    );
  }
}

void main() {
  testWidgets('report interpreter shows initial controls and saved selectors', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'patient_id': 42});

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: ReportInterpreterScreen(
            repository: _FakeReportInterpreterRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ready for a report'), findsOneWidget);
    expect(find.text('Analyze a report first'), findsOneWidget);
    expect(find.byTooltip('Report actions'), findsOneWidget);
    expect(find.text('Upload report'), findsNothing);

    await tester.tap(find.byTooltip('Report actions'));
    await tester.pumpAndSettle();

    expect(find.text('Upload report'), findsOneWidget);
    expect(find.text('No report selected'), findsOneWidget);
    expect(find.text('Load sample'), findsOneWidget);
    expect(find.text('Choose file'), findsOneWidget);
    expect(find.text('Analyze'), findsOneWidget);
    expect(find.text('Blood Work'), findsOneWidget);
    expect(find.text('2026-02-01'), findsOneWidget);
    expect(find.text('Analyze saved'), findsOneWidget);
  });

  testWidgets('report interpreter can load bundled sample report', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'patient_id': 42});

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: ReportInterpreterScreen(
            repository: _FakeReportInterpreterRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Report actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load sample'));
    await tester.pumpAndSettle();

    expect(find.textContaining('blood_report_sample.txt'), findsOneWidget);
  });
}

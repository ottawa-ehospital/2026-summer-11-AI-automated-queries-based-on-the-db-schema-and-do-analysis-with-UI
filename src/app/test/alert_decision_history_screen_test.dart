import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_health_app/data/models/health_alert_models.dart';
import 'package:smart_health_app/data/repositories/alert_decision_store.dart';
import 'package:smart_health_app/features/settings/screens/alert_decision_history_screen.dart';
import 'package:smart_health_app/services/health_alert_debug_scenario_runner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('alert decision history shows empty state', (tester) async {
    SharedPreferences.setMockInitialValues({'patient_id': '20'});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('No alert decisions yet'), findsOneWidget);
    expect(find.byTooltip('Test Alert Analyse'), findsOneWidget);
    expect(find.byTooltip('Clear history'), findsNothing);
  });

  testWidgets('alert decision history shows populated records', (tester) async {
    SharedPreferences.setMockInitialValues({'patient_id': '20'});
    await AlertDecisionStore().save('20', [_record()]);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Blood pressure reminder'), findsOneWidget);
    expect(find.text('notify'), findsOneWidget);
    expect(find.text('medium'), findsOneWidget);
    expect(find.text('test'), findsOneWidget);
    expect(find.textContaining('3-hour blood-pressure'), findsOneWidget);
    expect(find.byTooltip('Test Alert Analyse'), findsOneWidget);
    expect(find.byTooltip('Clear history'), findsOneWidget);
  });

  testWidgets('alert decision history clear action removes records', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'patient_id': '20'});
    await AlertDecisionStore().save('20', [_record()]);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Clear history'));
    await tester.pumpAndSettle();

    expect(find.text('No alert decisions yet'), findsOneWidget);
    expect(await AlertDecisionStore().load('20'), isEmpty);
  });

  testWidgets(
    'alert decision history debug action shows feedback and refreshes',
    (tester) async {
      SharedPreferences.setMockInitialValues({'patient_id': '20'});
      final store = AlertDecisionStore();
      final runner = _FakeDebugRunner(store: store)..pause = Completer<void>();

      await tester.pumpWidget(_app(store: store, debugScenarioRunner: runner));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Test Alert Analyse'));
      await tester.pumpAndSettle();

      expect(find.text('Debug data received'), findsOneWidget);
      expect(find.text('Falling blood pressure'), findsOneWidget);

      await tester.tap(find.text('Debug data received'));
      await tester.pump();

      expect(
        find.text('Debug Apple Health sync analysis triggered.'),
        findsOneWidget,
      );
      expect(runner.scenarios.single, HealthAlertDebugScenario.normalSync);

      runner.pause?.complete();
      await tester.pumpAndSettle();

      expect(find.text('Analysis returned successfully.'), findsOneWidget);
      expect(find.text('Blood pressure reminder'), findsOneWidget);
    },
  );

  testWidgets('alert decision history debug action handles missing patient', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final runner = _FakeDebugRunner();

    await tester.pumpWidget(_app(debugScenarioRunner: runner));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Test Alert Analyse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Falling blood pressure'));
    await tester.pumpAndSettle();

    expect(
      find.text('Patient context is required before running analysis.'),
      findsOneWidget,
    );
    expect(runner.scenarios, isEmpty);
  });
}

Widget _app({
  AlertDecisionStore? store,
  HealthAlertDebugScenarioRunner? debugScenarioRunner,
}) {
  return MaterialApp(
    home: AlertDecisionHistoryScreen(
      store: store,
      debugScenarioRunner: debugScenarioRunner,
    ),
  );
}

AlertDecisionRecord _record() {
  return AlertDecisionRecord.create(
    decision: const HealthAlertDecision(
      status: 'notification_decision',
      patientId: '20',
      eventType: HealthAlertEventType.bloodPressure,
      eventSourceId: 'hk-bp-widget',
      sourceMode: HealthAlertSourceMode.test,
      notify: true,
      severity: 'medium',
      title: 'Blood pressure reminder',
      body: 'Check whether you took your medication.',
      reason: 'Sustained elevation with medication context.',
      evidenceSummary: ['3-hour blood-pressure readings reviewed: 2'],
    ),
    notificationDispatched: true,
    storedAt: DateTime.utc(2026, 7, 2, 12),
  );
}

class _FakeDebugRunner extends HealthAlertDebugScenarioRunner {
  final AlertDecisionStore store;
  final scenarios = <HealthAlertDebugScenario>[];
  Completer<void>? pause;

  _FakeDebugRunner({AlertDecisionStore? store})
    : store = store ?? AlertDecisionStore();

  @override
  Future<HealthAlertDebugScenarioResult> run(
    HealthAlertDebugScenario scenario, {
    required String? patientId,
  }) async {
    scenarios.add(scenario);
    final pause = this.pause;
    if (pause != null) await pause.future;
    final record = _record();
    await store.append(patientId ?? '20', record);
    return HealthAlertDebugScenarioResult(
      scenario: scenario,
      record: record,
      message: 'Analysis returned successfully.',
      accepted: true,
    );
  }
}

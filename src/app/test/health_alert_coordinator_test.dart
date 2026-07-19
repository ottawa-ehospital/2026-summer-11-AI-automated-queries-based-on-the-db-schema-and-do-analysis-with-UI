import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_health_app/data/models/health_alert_models.dart';
import 'package:smart_health_app/services/health_alert_coordinator.dart';
import 'package:smart_health_app/services/health_alert_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('starts HealthKit bridge after patient id is available', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'patient_id': 20});
    final bridge = _FakeHealthAlertBridge();

    await tester.pumpWidget(
      _app(
        HealthAlertCoordinator(
          bridge: bridge,
          processEvent: _suppressedProcessor,
          patientPollInterval: const Duration(milliseconds: 50),
          child: const Scaffold(body: Text('Home')),
        ),
      ),
    );
    await tester.pump();

    expect(bridge.started, isTrue);
    expect(bridge.listenPatientId, '20');
    expect(find.text('Apple Health alert sync is listening.'), findsOneWidget);
  });

  testWidgets('processes native HealthKit events and shows analysis bubble', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'patient_id': 20});
    final bridge = _FakeHealthAlertBridge();
    final processed = <HealthAlertEvent>[];

    await tester.pumpWidget(
      _app(
        HealthAlertCoordinator(
          bridge: bridge,
          processEvent: (event) async {
            processed.add(event);
            return AlertDecisionRecord.create(
              decision: HealthAlertDecision(
                status: 'no_notification',
                patientId: event.patientId,
                eventType: event.eventType,
                eventSourceId: event.eventSourceId,
                sourceMode: event.sourceMode,
                notify: false,
                severity: 'info',
                reason: 'Debug analysis completed.',
              ),
              notificationDispatched: false,
            );
          },
          patientPollInterval: const Duration(milliseconds: 50),
          child: const Scaffold(body: Text('Home')),
        ),
      ),
    );
    await tester.pump();

    bridge.emit(
      HealthAlertEvent(
        patientId: '20',
        eventType: HealthAlertEventType.bloodPressure,
        eventSourceId: 'hk-bp-debug',
        eventTime: DateTime.utc(2026, 7, 2, 12),
        values: const {'systolic': 140, 'diastolic': 90},
        unit: 'mmHg',
      ),
    );
    await tester.pump();

    expect(processed.single.eventSourceId, 'hk-bp-debug');
    expect(
      find.text('Health alert analyzed: Debug analysis completed.'),
      findsOneWidget,
    );
  });

  testWidgets('does not reconcile when HealthKit bridge start fails', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'patient_id': 20});
    final bridge = _FakeHealthAlertBridge()..startFailure = 'missing plugin';

    await tester.pumpWidget(
      _app(
        HealthAlertCoordinator(
          bridge: bridge,
          processEvent: _suppressedProcessor,
          patientPollInterval: const Duration(milliseconds: 50),
          child: const Scaffold(body: Text('Home')),
        ),
      ),
    );
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(bridge.started, isTrue);
    expect(bridge.reconciled, isFalse);
    expect(
      find.text('Apple Health alert sync could not start: missing plugin'),
      findsOneWidget,
    );
  });
}

Widget _app(Widget home) {
  return MaterialApp(home: home);
}

Future<AlertDecisionRecord> _suppressedProcessor(HealthAlertEvent event) async {
  return AlertDecisionRecord.create(
    decision: HealthAlertDecision(
      status: 'no_notification',
      patientId: event.patientId,
      eventType: event.eventType,
      eventSourceId: event.eventSourceId,
      sourceMode: event.sourceMode,
      notify: false,
      severity: 'info',
      reason: 'No notification.',
    ),
    notificationDispatched: false,
  );
}

class _FakeHealthAlertBridge implements HealthAlertBridge {
  bool started = false;
  bool reconciled = false;
  String? startFailure;
  String? listenPatientId;
  void Function(HealthAlertEvent event)? _handler;

  @override
  Future<void> start() async {
    started = true;
    if (startFailure != null) throw startFailure!;
  }

  @override
  Future<void> reconcile() async {
    reconciled = true;
  }

  @override
  void listen({
    required String patientId,
    required void Function(HealthAlertEvent event) onEvent,
  }) {
    listenPatientId = patientId;
    _handler = onEvent;
  }

  void emit(HealthAlertEvent event) {
    _handler?.call(event);
  }
}

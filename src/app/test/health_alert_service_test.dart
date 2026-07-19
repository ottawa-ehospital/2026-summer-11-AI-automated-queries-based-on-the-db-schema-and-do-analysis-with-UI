import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_health_app/core/network/api_exception.dart';
import 'package:smart_health_app/data/models/health_alert_models.dart';
import 'package:smart_health_app/data/models/wearable_models.dart';
import 'package:smart_health_app/data/repositories/alert_decision_store.dart';
import 'package:smart_health_app/data/repositories/health_alert_repository.dart';
import 'package:smart_health_app/data/repositories/wearable_ingestion_repository.dart';
import 'package:smart_health_app/services/health_alert_debug_scenario_runner.dart';
import 'package:smart_health_app/services/health_alert_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('invalid events are stored locally without notification', () async {
    final dispatcher = _FakeDispatcher();
    final service = HealthAlertService(
      repository: _FakeHealthAlertClient(),
      store: AlertDecisionStore(),
      dispatcher: dispatcher,
      wearableIngestionClient: _FakeWearableIngestionClient(),
    );

    final record = await service.processEvent(
      _event(values: const {'systolic': 300, 'diastolic': 90}),
    );
    final stored = await AlertDecisionStore().load('20');

    expect(record.decision.status, 'invalid_event');
    expect(record.notificationDispatched, isFalse);
    expect(dispatcher.notifications, isEmpty);
    expect(stored.single.decision.status, 'invalid_event');
  });

  test('notification decisions are dispatched and stored', () async {
    final dispatcher = _FakeDispatcher();
    final service = HealthAlertService(
      repository: _FakeHealthAlertClient(
        decision: _decision(notify: true, title: 'Medication check'),
      ),
      store: AlertDecisionStore(),
      dispatcher: dispatcher,
      wearableIngestionClient: _FakeWearableIngestionClient(),
    );

    final record = await service.processEvent(_event());
    final stored = await AlertDecisionStore().load('20');

    expect(record.notificationDispatched, isTrue);
    expect(dispatcher.notifications.single.title, 'Medication check');
    expect(stored.single.decision.notify, isTrue);
  });

  test('suppressed decisions are stored without notification', () async {
    final dispatcher = _FakeDispatcher();
    final service = HealthAlertService(
      repository: _FakeHealthAlertClient(decision: _decision(notify: false)),
      store: AlertDecisionStore(),
      dispatcher: dispatcher,
      wearableIngestionClient: _FakeWearableIngestionClient(),
    );

    final record = await service.processEvent(_event());

    expect(record.decision.status, 'no_notification');
    expect(record.notificationDispatched, isFalse);
    expect(dispatcher.notifications, isEmpty);
  });

  test('notification dispatch failures are stored with the decision', () async {
    final dispatcher = _FakeDispatcher()..failure = 'permission denied';
    final service = HealthAlertService(
      repository: _FakeHealthAlertClient(
        decision: _decision(notify: true, title: 'Medication check'),
      ),
      store: AlertDecisionStore(),
      dispatcher: dispatcher,
      wearableIngestionClient: _FakeWearableIngestionClient(),
    );

    final record = await service.processEvent(_event());

    expect(record.notificationDispatched, isFalse);
    expect(record.dispatchFailure, 'permission denied');
    expect(dispatcher.notifications.single.title, 'Medication check');
  });

  test('valid data test notification fires before analysis decision', () async {
    final dispatcher = _FakeDispatcher();
    final service = HealthAlertService(
      repository: _FakeHealthAlertClient(decision: _decision(notify: false)),
      store: AlertDecisionStore(),
      dispatcher: dispatcher,
      wearableIngestionClient: _FakeWearableIngestionClient(),
    );

    await service.processEvent(_event(), validDataTestNotification: true);

    expect(
      dispatcher.notifications.single.title,
      '[TEST] Apple Health data received',
    );
    expect(dispatcher.notifications.single.testNotification, isTrue);
  });

  test(
    'test-source notification decisions are marked as test notifications',
    () async {
      final dispatcher = _FakeDispatcher();
      final service = HealthAlertService(
        repository: _FakeHealthAlertClient(
          decision: _decision(
            notify: true,
            sourceMode: HealthAlertSourceMode.test,
            title: 'Blood pressure reminder',
          ),
        ),
        store: AlertDecisionStore(),
        dispatcher: dispatcher,
        wearableIngestionClient: _FakeWearableIngestionClient(),
      );

      await service.processEvent(
        _event(sourceMode: HealthAlertSourceMode.test),
      );

      expect(
        dispatcher.notifications.single.title,
        '[TEST] Blood pressure reminder',
      );
      expect(dispatcher.notifications.single.testNotification, isTrue);
    },
  );

  test(
    'HealthKit bridge injects the active patient id into native payload',
    () async {
      const channel = MethodChannel('smart_health/healthkit_alerts');
      final events = <HealthAlertEvent>[];
      HealthKitAlertBridge().listen(patientId: '20', onEvent: events.add);

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            channel.name,
            channel.codec.encodeMethodCall(
              MethodCall('healthAlertEvent', {
                'event_type': HealthAlertEventType.bloodPressure,
                'event_source_id': 'hk-bp-bridge',
                'event_time': '2026-07-02T12:00:00Z',
                'values': {'systolic': 140, 'diastolic': 90},
                'unit': 'mmHg',
                'source': 'apple_health',
              }),
            ),
            (_) {},
          );

      expect(events.single.patientId, '20');
      expect(events.single.eventSourceId, 'hk-bp-bridge');
      expect(events.single.values['systolic'], 140);
    },
  );

  test(
    'supporting HealthKit samples route through wearable ingestion',
    () async {
      final ingestion = _FakeWearableIngestionClient();
      final service = HealthAlertService(
        repository: _FakeHealthAlertClient(
          decision: _decision(
            notify: false,
            eventType: HealthAlertEventType.heartRate,
          ),
        ),
        store: AlertDecisionStore(),
        dispatcher: _FakeDispatcher(),
        wearableIngestionClient: ingestion,
      );

      await service.processEvent(
        HealthAlertEvent(
          patientId: '20',
          eventType: HealthAlertEventType.heartRate,
          eventSourceId: 'hk-hr-1',
          eventTime: DateTime.parse('2026-07-02T12:00:00Z'),
          values: const {'heart_rate': 88},
        ),
      );

      expect(ingestion.samples.single.heartRate, 88);
      expect(ingestion.samples.single.source, WearableSource.appleHealth);
      expect(
        ingestion.samples.single.sourceMetadata['health_alert_event_source_id'],
        'hk-hr-1',
      );
    },
  );

  test('alert decision store keeps newest 100 records', () async {
    final store = AlertDecisionStore();

    for (var index = 0; index < 105; index += 1) {
      await store.append(
        '20',
        AlertDecisionRecord.create(
          decision: _decision(eventSourceId: 'event-$index'),
          notificationDispatched: false,
          storedAt: DateTime.utc(2026, 7, 2, 12, index),
        ),
      );
    }

    final records = await store.load('20');
    expect(records, hasLength(100));
    expect(records.first.decision.eventSourceId, 'event-104');
    expect(records.last.decision.eventSourceId, 'event-5');
  });

  test('alert decision records survive json round trip', () {
    final record = AlertDecisionRecord.create(
      decision: _decision(notify: true, eventSourceId: 'round-trip'),
      notificationDispatched: true,
      storedAt: DateTime.utc(2026, 7, 2, 12),
    );

    final decoded = AlertDecisionRecord.fromJson(
      jsonDecode(jsonEncode(record.toJson())) as Map<String, dynamic>,
    );

    expect(decoded.decision.eventSourceId, 'round-trip');
    expect(decoded.notificationDispatched, isTrue);
  });

  test(
    'debug normal sync scenario uses alert service and test notification',
    () async {
      final dispatcher = _FakeDispatcher();
      final client = _FakeHealthAlertClient();
      final runner = HealthAlertDebugScenarioRunner(
        service: HealthAlertService(
          repository: client,
          store: AlertDecisionStore(),
          dispatcher: dispatcher,
          wearableIngestionClient: _FakeWearableIngestionClient(),
        ),
        now: () => DateTime.parse('2026-07-02T12:00:00Z'),
      );

      final result = await runner.run(
        HealthAlertDebugScenario.normalSync,
        patientId: '20',
      );

      expect(result.analysisReturned, isTrue);
      expect(client.events.single.eventType, HealthAlertEventType.heartRate);
      expect(client.events.single.sourceMode, HealthAlertSourceMode.test);
      expect(
        client.events.single.sourceMetadata['debug_scenario'],
        'normal_apple_health_sync',
      );
      expect(
        dispatcher.notifications.single.title,
        '[TEST] Apple Health data received',
      );
      expect(dispatcher.notifications.single.testNotification, isTrue);
      expect(
        (await AlertDecisionStore().load('20')).single.decision.isTestSource,
        isTrue,
      );
    },
  );

  test('debug falling blood pressure scenario sends trend context', () async {
    final dispatcher = _FakeDispatcher();
    final client = _FakeHealthAlertClient(
      decisionBuilder: (event) => _decision(
        notify: true,
        patientId: event.patientId,
        eventType: event.eventType,
        eventSourceId: event.eventSourceId,
        sourceMode: event.sourceMode,
        title: 'Blood pressure medication check',
      ),
    );
    final runner = HealthAlertDebugScenarioRunner(
      service: HealthAlertService(
        repository: client,
        store: AlertDecisionStore(),
        dispatcher: dispatcher,
        wearableIngestionClient: _FakeWearableIngestionClient(),
      ),
      now: () => DateTime.parse('2026-07-02T12:00:00Z'),
    );

    final result = await runner.run(
      HealthAlertDebugScenario.fallingBloodPressure,
      patientId: '20',
    );
    final event = client.events.single;

    expect(result.notificationDispatched, isTrue);
    expect(event.eventType, HealthAlertEventType.bloodPressure);
    expect(event.values['trend_readings'], isA<List>());
    expect(event.values['systolic'], 136);
    expect(event.values['diastolic'], 84);
    expect(event.sourceMetadata['debug_scenario'], 'falling_blood_pressure');
    expect(event.sourceMetadata.containsKey('medication_context'), isFalse);
    expect(dispatcher.notifications.single.title, startsWith('[TEST]'));
  });

  test('debug scenario requires patient context', () async {
    final client = _FakeHealthAlertClient();
    final dispatcher = _FakeDispatcher();
    final runner = HealthAlertDebugScenarioRunner(
      service: HealthAlertService(
        repository: client,
        store: AlertDecisionStore(),
        dispatcher: dispatcher,
        wearableIngestionClient: _FakeWearableIngestionClient(),
      ),
    );

    final result = await runner.run(
      HealthAlertDebugScenario.normalSync,
      patientId: null,
    );

    expect(result.accepted, isFalse);
    expect(client.events, isEmpty);
    expect(dispatcher.notifications, isEmpty);
  });

  test('debug scenario records backend failures', () async {
    final runner = HealthAlertDebugScenarioRunner(
      service: HealthAlertService(
        repository: _FakeHealthAlertClient(
          exception: const ApiException('backend unavailable'),
        ),
        store: AlertDecisionStore(),
        dispatcher: _FakeDispatcher(),
        wearableIngestionClient: _FakeWearableIngestionClient(),
      ),
      now: () => DateTime.parse('2026-07-02T12:00:00Z'),
    );

    final result = await runner.run(
      HealthAlertDebugScenario.fallingBloodPressure,
      patientId: '20',
    );

    expect(result.accepted, isFalse);
    expect(result.record?.dispatchFailure, 'backend unavailable');
    expect(
      (await AlertDecisionStore().load('20')).single.dispatchFailure,
      'backend unavailable',
    );
  });
}

class _FakeHealthAlertClient implements HealthAlertAnalysisClient {
  final HealthAlertDecision? decision;
  final HealthAlertDecision Function(HealthAlertEvent event)? decisionBuilder;
  final ApiException? exception;
  final events = <HealthAlertEvent>[];

  _FakeHealthAlertClient({this.decision, this.decisionBuilder, this.exception});

  @override
  Future<HealthAlertDecision> analyze(HealthAlertEvent event) async {
    events.add(event);
    final exception = this.exception;
    if (exception != null) throw exception;
    final decisionBuilder = this.decisionBuilder;
    if (decisionBuilder != null) return decisionBuilder(event);
    return decision ??
        _decision(
          patientId: event.patientId,
          eventType: event.eventType,
          eventSourceId: event.eventSourceId,
          sourceMode: event.sourceMode,
        );
  }
}

class _FakeDispatcher implements HealthAlertNotificationDispatcher {
  final notifications = <_Notification>[];
  String? failure;

  @override
  Future<String?> show({
    required String title,
    required String body,
    required bool testNotification,
  }) async {
    notifications.add(
      _Notification(
        title: title,
        body: body,
        testNotification: testNotification,
      ),
    );
    return failure;
  }
}

class _FakeWearableIngestionClient implements WearableIngestionClient {
  final samples = <WearableSample>[];
  final workouts = <WearableWorkout>[];

  @override
  Future<WearableIngestionResult> ingest(WearableSample sample) async {
    samples.add(sample);
    return WearableIngestionResult(
      status: 'ingested',
      patientId: sample.patientId,
      acceptedMetrics: sample.acceptedMetrics,
      source: sample.source,
      timestamp: sample.timestamp.toIso8601String(),
      recordedOn: (sample.recordedOn ?? sample.timestamp).toIso8601String(),
    );
  }

  @override
  Future<WearableWorkoutIngestionResult> ingestWorkout(
    WearableWorkout workout,
  ) async {
    workouts.add(workout);
    return WearableWorkoutIngestionResult(
      status: 'ingested',
      patientId: workout.patientId,
      sourceProvider: workout.sourceProvider,
      sourceWorkoutId: workout.sourceWorkoutId,
      workoutType: workout.workoutType,
      startTime: workout.startTime.toIso8601String(),
      endTime: workout.endTime.toIso8601String(),
      durationSeconds: workout.durationSeconds,
    );
  }

  @override
  Future<WearableWorkoutBatchIngestionResult> ingestWorkoutBatch(
    List<WearableWorkout> workouts,
  ) {
    throw UnimplementedError();
  }
}

class _Notification {
  final String title;
  final String body;
  final bool testNotification;

  const _Notification({
    required this.title,
    required this.body,
    required this.testNotification,
  });
}

HealthAlertEvent _event({
  Map<String, dynamic> values = const {'systolic': 142, 'diastolic': 92},
  String sourceMode = HealthAlertSourceMode.production,
}) {
  return HealthAlertEvent(
    patientId: '20',
    eventType: HealthAlertEventType.bloodPressure,
    eventSourceId: 'hk-bp-1',
    eventTime: DateTime.parse('2026-07-02T12:00:00Z'),
    values: values,
    unit: 'mmHg',
    sourceMode: sourceMode,
  );
}

HealthAlertDecision _decision({
  bool notify = false,
  String patientId = '20',
  String eventType = HealthAlertEventType.bloodPressure,
  String eventSourceId = 'hk-bp-1',
  String sourceMode = HealthAlertSourceMode.production,
  String? title,
}) {
  return HealthAlertDecision(
    status: notify ? 'notification_decision' : 'no_notification',
    patientId: patientId,
    eventType: eventType,
    eventSourceId: eventSourceId,
    sourceMode: sourceMode,
    notify: notify,
    severity: notify ? 'medium' : 'info',
    title: title,
    body: notify ? 'Check your medication routine.' : null,
    reason: 'Test decision.',
    evidenceSummary: const ['3-hour blood-pressure readings reviewed: 2'],
  );
}

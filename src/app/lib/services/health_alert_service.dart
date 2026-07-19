import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/network/api_exception.dart';
import '../data/models/health_alert_models.dart';
import '../data/models/wearable_models.dart';
import '../data/repositories/alert_decision_store.dart';
import '../data/repositories/health_alert_repository.dart';
import '../data/repositories/wearable_ingestion_repository.dart';

abstract class HealthAlertNotificationDispatcher {
  Future<String?> show({
    required String title,
    required String body,
    required bool testNotification,
  });
}

class LocalHealthAlertNotificationDispatcher
    implements HealthAlertNotificationDispatcher {
  static const MethodChannel _iosNotificationChannel = MethodChannel(
    'smart_health/health_alert_notifications',
  );

  final FlutterLocalNotificationsPlugin _plugin;

  LocalHealthAlertNotificationDispatcher({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  Future<String?> show({
    required String title,
    required String body,
    required bool testNotification,
  }) async {
    if (!kIsWeb && Platform.isIOS) {
      return _showNativeIosNotification(
        title: title,
        body: body,
        testNotification: testNotification,
      );
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: darwin);
    try {
      await _plugin.initialize(settings);
      final permissionGranted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      if (permissionGranted == false) {
        return 'notification permission denied';
      }

      const androidDetails = AndroidNotificationDetails(
        'health_alerts',
        'Health Alerts',
        channelDescription: 'Health alert and test notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
      );
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> _showNativeIosNotification({
    required String title,
    required String body,
    required bool testNotification,
  }) async {
    try {
      final failure = await _iosNotificationChannel.invokeMethod<String>(
        'showHealthAlertNotification',
        {'title': title, 'body': body, 'testNotification': testNotification},
      );
      return failure;
    } catch (error) {
      return error.toString();
    }
  }
}

abstract class HealthAlertBridge {
  Future<void> start();
  Future<void> reconcile();
  void listen({
    required String patientId,
    required void Function(HealthAlertEvent event) onEvent,
  });
}

class HealthKitAlertBridge implements HealthAlertBridge {
  static const MethodChannel _channel = MethodChannel(
    'smart_health/healthkit_alerts',
  );

  @override
  Future<void> start() => _channel.invokeMethod<void>('startHealthAlerts');

  @override
  Future<void> reconcile() =>
      _channel.invokeMethod<void>('reconcileHealthAlerts');

  @override
  void listen({
    required String patientId,
    required void Function(HealthAlertEvent event) onEvent,
  }) {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'healthAlertEvent' || call.arguments is! Map) return;
      final payload = Map<String, dynamic>.from(call.arguments as Map);
      payload['patient_id'] = patientId;
      onEvent(HealthAlertEvent.fromJson(payload));
    });
  }
}

class HealthAlertService {
  final HealthAlertAnalysisClient _repository;
  final AlertDecisionStore _store;
  final HealthAlertNotificationDispatcher _dispatcher;
  final WearableIngestionClient _wearableIngestionClient;

  HealthAlertService({
    HealthAlertAnalysisClient? repository,
    AlertDecisionStore? store,
    HealthAlertNotificationDispatcher? dispatcher,
    WearableIngestionClient? wearableIngestionClient,
  }) : _repository = repository ?? HealthAlertRepository(),
       _store = store ?? AlertDecisionStore(),
       _dispatcher = dispatcher ?? LocalHealthAlertNotificationDispatcher(),
       _wearableIngestionClient =
           wearableIngestionClient ?? WearableIngestionRepository();

  Future<AlertDecisionRecord> processEvent(
    HealthAlertEvent event, {
    bool validDataTestNotification = false,
  }) async {
    final validationError = event.validate();
    if (validationError != null) {
      final decision = _localDecision(
        event,
        status: 'invalid_event',
        notify: false,
        severity: 'none',
        reason: validationError,
      );
      final record = AlertDecisionRecord.create(
        decision: decision,
        notificationDispatched: false,
      );
      await _store.append(event.patientId, record);
      return record;
    }

    if (validDataTestNotification) {
      await _dispatcher.show(
        title: '[TEST] Apple Health data received',
        body:
            '${event.eventType} event ${event.eventSourceId} reached the app.',
        testNotification: true,
      );
    }
    await _ingestWearableContext(event);

    try {
      final decision = await _repository.analyze(event);
      return _handleDecision(decision);
    } on ApiException catch (error) {
      final decision = _localDecision(
        event,
        status: 'invalid_event',
        notify: false,
        severity: 'none',
        reason: error.message,
      );
      final record = AlertDecisionRecord.create(
        decision: decision,
        notificationDispatched: false,
        dispatchFailure: error.message,
      );
      await _store.append(event.patientId, record);
      return record;
    }
  }

  Future<AlertDecisionRecord> injectTestBloodPressure({
    required String patientId,
    required double systolic,
    required double diastolic,
  }) {
    return processEvent(
      HealthAlertEvent.testBloodPressure(
        patientId: patientId,
        systolic: systolic,
        diastolic: diastolic,
      ),
    );
  }

  Future<AlertDecisionRecord> _handleDecision(
    HealthAlertDecision decision,
  ) async {
    var dispatched = false;
    String? failure;
    if (decision.notify) {
      final title = decision.title ?? 'Health reminder';
      final body = decision.body ?? decision.reason;
      failure = await _dispatcher.show(
        title: decision.isTestSource ? '[TEST] $title' : title,
        body: body,
        testNotification: decision.isTestSource,
      );
      dispatched = failure == null;
    }
    final record = AlertDecisionRecord.create(
      decision: decision,
      notificationDispatched: dispatched,
      dispatchFailure: failure,
    );
    await _store.append(decision.patientId, record);
    return record;
  }

  Future<void> _ingestWearableContext(HealthAlertEvent event) async {
    try {
      final sample = _wearableSampleFor(event);
      if (sample != null) {
        await _wearableIngestionClient.ingest(sample);
        return;
      }
      final workout = _wearableWorkoutFor(event);
      if (workout != null) {
        await _wearableIngestionClient.ingestWorkout(workout);
      }
    } on ApiException {
      // Alert analysis can still proceed when context ingestion is unavailable.
    }
  }

  WearableSample? _wearableSampleFor(HealthAlertEvent event) {
    final heartRate = _number(event.values['heart_rate']);
    final steps = _number(event.values['steps']);
    final sleep =
        _number(event.values['sleep']) ??
        _secondsToHours(_number(event.values['sleep_seconds']));
    if (heartRate == null && steps == null && sleep == null) return null;
    return WearableSample(
      patientId: event.patientId,
      heartRate: heartRate,
      steps: steps,
      sleep: sleep,
      timestamp: event.eventTime,
      recordedOn: event.eventTime,
      source: WearableSource.appleHealth,
      sourceMetadata: {
        ...event.sourceMetadata,
        'health_alert_event_source_id': event.eventSourceId,
        'health_alert_event_type': event.eventType,
      },
    );
  }

  WearableWorkout? _wearableWorkoutFor(HealthAlertEvent event) {
    if (event.eventType != HealthAlertEventType.workout) return null;
    final durationSeconds = _number(event.values['duration_seconds']);
    if (durationSeconds == null || durationSeconds <= 0) return null;
    final duration = durationSeconds.round();
    final endTime = event.eventTime;
    return WearableWorkout(
      patientId: event.patientId,
      sourceProvider: WearableSource.appleHealth,
      sourceWorkoutId: event.eventSourceId,
      workoutType: event.values['workout_type']?.toString() ?? 'workout',
      workoutTypeRaw: event.values['workout_activity_type']?.toString(),
      startTime: endTime.subtract(Duration(seconds: duration)),
      endTime: endTime,
      durationSeconds: duration,
      distanceMeters: _number(event.values['distance_meters']),
      activeEnergyKcal: _number(event.values['active_energy_kcal']),
      totalEnergyKcal: _number(event.values['total_energy_kcal']),
      sourceMetadata: event.sourceMetadata,
      rawPayload: event.values,
    );
  }

  HealthAlertDecision _localDecision(
    HealthAlertEvent event, {
    required String status,
    required bool notify,
    required String severity,
    required String reason,
  }) {
    return HealthAlertDecision(
      status: status,
      patientId: event.patientId,
      eventType: event.eventType,
      eventSourceId: event.eventSourceId,
      sourceMode: event.sourceMode,
      notify: notify,
      severity: severity,
      reason: reason,
      trace: const {'selected_workflow': 'local_health_alert_service'},
    );
  }

  double? _number(dynamic value) {
    if (value is bool) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  double? _secondsToHours(double? seconds) {
    if (seconds == null) return null;
    return seconds / 3600;
  }
}

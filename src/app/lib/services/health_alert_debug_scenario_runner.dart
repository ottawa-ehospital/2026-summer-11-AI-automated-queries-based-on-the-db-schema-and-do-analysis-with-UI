import '../data/models/health_alert_models.dart';
import 'health_alert_service.dart';

enum HealthAlertDebugScenario { normalSync, fallingBloodPressure }

class HealthAlertDebugScenarioResult {
  final HealthAlertDebugScenario scenario;
  final AlertDecisionRecord? record;
  final String message;
  final bool accepted;

  const HealthAlertDebugScenarioResult({
    required this.scenario,
    required this.record,
    required this.message,
    required this.accepted,
  });

  bool get analysisReturned =>
      accepted && record != null && record!.decision.status != 'invalid_event';

  bool get notificationDispatched => record?.notificationDispatched ?? false;

  bool get suppressed =>
      analysisReturned && record != null && !record!.decision.notify;
}

class HealthAlertDebugScenarioRunner {
  final HealthAlertService _service;
  final DateTime Function() _now;

  HealthAlertDebugScenarioRunner({
    HealthAlertService? service,
    DateTime Function()? now,
  }) : _service = service ?? HealthAlertService(),
       _now = now ?? DateTime.now;

  Future<HealthAlertDebugScenarioResult> run(
    HealthAlertDebugScenario scenario, {
    required String? patientId,
  }) async {
    if (patientId == null || patientId.trim().isEmpty) {
      return HealthAlertDebugScenarioResult(
        scenario: scenario,
        record: null,
        message: 'Patient context is required before running alert analysis.',
        accepted: false,
      );
    }

    return switch (scenario) {
      HealthAlertDebugScenario.normalSync => _runNormalSync(patientId.trim()),
      HealthAlertDebugScenario.fallingBloodPressure => _runFallingBloodPressure(
        patientId.trim(),
      ),
    };
  }

  Future<HealthAlertDebugScenarioResult> _runNormalSync(
    String patientId,
  ) async {
    final timestamp = _now().toUtc();
    final event = HealthAlertEvent(
      patientId: patientId,
      eventType: HealthAlertEventType.heartRate,
      eventSourceId: 'debug-health-sync-${timestamp.millisecondsSinceEpoch}',
      eventTime: timestamp,
      values: const {'heart_rate': 72},
      unit: 'count/min',
      source: 'apple_health',
      sourceMode: HealthAlertSourceMode.test,
      sourceMetadata: const {
        'debug_scenario': 'normal_apple_health_sync',
        'injected': true,
      },
    );
    final record = await _service.processEvent(
      event,
      validDataTestNotification: true,
    );
    return HealthAlertDebugScenarioResult(
      scenario: HealthAlertDebugScenario.normalSync,
      record: record,
      message: _messageFor(record),
      accepted: record.decision.status != 'invalid_event',
    );
  }

  Future<HealthAlertDebugScenarioResult> _runFallingBloodPressure(
    String patientId,
  ) async {
    final timestamp = _now().toUtc();
    final readings = [
      _bpReading(timestamp.subtract(const Duration(hours: 3)), 166, 102),
      _bpReading(timestamp.subtract(const Duration(hours: 2)), 158, 96),
      _bpReading(timestamp.subtract(const Duration(hours: 1)), 146, 90),
      _bpReading(timestamp, 136, 84),
    ];
    final event = HealthAlertEvent(
      patientId: patientId,
      eventType: HealthAlertEventType.bloodPressure,
      eventSourceId: 'debug-falling-bp-${timestamp.millisecondsSinceEpoch}',
      eventTime: timestamp,
      values: {'systolic': 136, 'diastolic': 84, 'trend_readings': readings},
      unit: 'mmHg',
      source: 'apple_health',
      sourceMode: HealthAlertSourceMode.test,
      sourceMetadata: {
        'debug_scenario': 'falling_blood_pressure',
        'injected': true,
        'analysis_window_hours': 3,
      },
    );
    final record = await _service.processEvent(event);
    return HealthAlertDebugScenarioResult(
      scenario: HealthAlertDebugScenario.fallingBloodPressure,
      record: record,
      message: _messageFor(record),
      accepted: record.decision.status != 'invalid_event',
    );
  }

  Map<String, dynamic> _bpReading(
    DateTime measuredAt,
    int systolic,
    int diastolic,
  ) {
    return {
      'time': measuredAt.toIso8601String(),
      'systolic': systolic,
      'diastolic': diastolic,
      'unit': 'mmHg',
    };
  }

  String _messageFor(AlertDecisionRecord record) {
    if (record.decision.status == 'invalid_event') {
      return 'Debug alert analysis could not be accepted.';
    }
    if (record.dispatchFailure != null) {
      return 'Analysis returned, but notification was not sent.';
    }
    if (record.notificationDispatched) {
      return 'Analysis returned successfully and notification was sent.';
    }
    if (record.decision.notify) {
      return 'Analysis returned successfully; notification was not sent.';
    }
    return 'Analysis returned successfully with no notification.';
  }
}

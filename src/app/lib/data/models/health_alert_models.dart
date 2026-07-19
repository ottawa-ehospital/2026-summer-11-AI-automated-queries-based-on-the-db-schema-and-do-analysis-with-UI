class HealthAlertEventType {
  static const bloodPressure = 'blood_pressure';
  static const heartRate = 'heart_rate';
  static const sleep = 'sleep';
  static const activity = 'activity';
  static const workout = 'workout';

  static const supported = {bloodPressure, heartRate, sleep, activity, workout};
}

class HealthAlertSourceMode {
  static const production = 'production';
  static const test = 'test';
  static const simulation = 'simulation';
}

class HealthAlertEvent {
  final String patientId;
  final String eventType;
  final String eventSourceId;
  final DateTime eventTime;
  final Map<String, dynamic> values;
  final String? unit;
  final String source;
  final String sourceMode;
  final Map<String, dynamic> sourceMetadata;

  const HealthAlertEvent({
    required this.patientId,
    required this.eventType,
    required this.eventSourceId,
    required this.eventTime,
    required this.values,
    this.unit,
    this.source = 'apple_health',
    this.sourceMode = HealthAlertSourceMode.production,
    this.sourceMetadata = const {},
  });

  bool get isSupported => HealthAlertEventType.supported.contains(eventType);

  bool get isTestSource =>
      sourceMode == HealthAlertSourceMode.test ||
      sourceMode == HealthAlertSourceMode.simulation;

  String? validate() {
    if (patientId.trim().isEmpty) return 'patient_id is required.';
    if (!isSupported) return 'Unsupported event type: $eventType';
    if (eventSourceId.trim().isEmpty) return 'event_source_id is required.';
    if (eventType == HealthAlertEventType.bloodPressure) {
      final systolic = _numValue(
        values['systolic'] ?? values['systolic_mm_hg'],
      );
      final diastolic = _numValue(
        values['diastolic'] ?? values['diastolic_mm_hg'],
      );
      if (systolic == null || diastolic == null) {
        return 'Blood pressure events require systolic and diastolic values.';
      }
      if (systolic <= 0 ||
          diastolic <= 0 ||
          systolic > 260 ||
          diastolic > 180) {
        return 'Blood pressure values are outside the supported range.';
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'patient_id': patientId,
    'event_type': eventType,
    'event_source_id': eventSourceId,
    'event_time': eventTime.toIso8601String(),
    'values': values,
    if (unit != null) 'unit': unit,
    'source': source,
    'source_mode': sourceMode,
    if (sourceMetadata.isNotEmpty) 'source_metadata': sourceMetadata,
  };

  factory HealthAlertEvent.fromJson(Map<String, dynamic> json) {
    return HealthAlertEvent(
      patientId: json['patient_id']?.toString() ?? '',
      eventType: json['event_type']?.toString() ?? '',
      eventSourceId: json['event_source_id']?.toString() ?? '',
      eventTime:
          DateTime.tryParse(json['event_time']?.toString() ?? '') ??
          DateTime.now(),
      values: _stringMap(json['values']),
      unit: json['unit']?.toString(),
      source: json['source']?.toString() ?? 'apple_health',
      sourceMode:
          json['source_mode']?.toString() ?? HealthAlertSourceMode.production,
      sourceMetadata: _stringMap(json['source_metadata']),
    );
  }

  static HealthAlertEvent testBloodPressure({
    required String patientId,
    required double systolic,
    required double diastolic,
    DateTime? eventTime,
  }) {
    final timestamp = eventTime ?? DateTime.now();
    return HealthAlertEvent(
      patientId: patientId,
      eventType: HealthAlertEventType.bloodPressure,
      eventSourceId: 'test-bp-${timestamp.toUtc().millisecondsSinceEpoch}',
      eventTime: timestamp,
      values: {'systolic': systolic, 'diastolic': diastolic},
      unit: 'mmHg',
      source: 'test_injection',
      sourceMode: HealthAlertSourceMode.test,
      sourceMetadata: const {'injected': true},
    );
  }
}

class HealthAlertDecision {
  final String status;
  final String patientId;
  final String eventType;
  final String eventSourceId;
  final String sourceMode;
  final bool notify;
  final String severity;
  final String? title;
  final String? body;
  final String reason;
  final List<String> evidenceSummary;
  final String? recommendationCategory;
  final Map<String, dynamic> freshness;
  final Map<String, dynamic> trace;

  const HealthAlertDecision({
    required this.status,
    required this.patientId,
    required this.eventType,
    required this.eventSourceId,
    required this.sourceMode,
    required this.notify,
    required this.severity,
    this.title,
    this.body,
    required this.reason,
    this.evidenceSummary = const [],
    this.recommendationCategory,
    this.freshness = const {},
    this.trace = const {},
  });

  bool get isTestSource =>
      sourceMode == HealthAlertSourceMode.test ||
      sourceMode == HealthAlertSourceMode.simulation;

  factory HealthAlertDecision.fromJson(Map<String, dynamic> json) {
    final rawEvidence = json['evidence_summary'];
    return HealthAlertDecision(
      status: json['status']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      eventType: json['event_type']?.toString() ?? '',
      eventSourceId: json['event_source_id']?.toString() ?? '',
      sourceMode:
          json['source_mode']?.toString() ?? HealthAlertSourceMode.production,
      notify: json['notify'] == true,
      severity: json['severity']?.toString() ?? 'none',
      title: json['title']?.toString(),
      body: json['body']?.toString(),
      reason: json['reason']?.toString() ?? '',
      evidenceSummary: rawEvidence is List
          ? rawEvidence.map((item) => item.toString()).toList()
          : const [],
      recommendationCategory: json['recommendation_category']?.toString(),
      freshness: _stringMap(json['freshness']),
      trace: _stringMap(json['trace']),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'patient_id': patientId,
    'event_type': eventType,
    'event_source_id': eventSourceId,
    'source_mode': sourceMode,
    'notify': notify,
    'severity': severity,
    if (title != null) 'title': title,
    if (body != null) 'body': body,
    'reason': reason,
    'evidence_summary': evidenceSummary,
    if (recommendationCategory != null)
      'recommendation_category': recommendationCategory,
    'freshness': freshness,
    'trace': trace,
  };
}

class AlertDecisionRecord {
  final String id;
  final HealthAlertDecision decision;
  final DateTime storedAt;
  final bool notificationDispatched;
  final String? dispatchFailure;

  const AlertDecisionRecord({
    required this.id,
    required this.decision,
    required this.storedAt,
    required this.notificationDispatched,
    this.dispatchFailure,
  });

  factory AlertDecisionRecord.create({
    required HealthAlertDecision decision,
    required bool notificationDispatched,
    String? dispatchFailure,
    DateTime? storedAt,
  }) {
    final timestamp = storedAt ?? DateTime.now();
    return AlertDecisionRecord(
      id: '${decision.eventSourceId}-${timestamp.toUtc().millisecondsSinceEpoch}',
      decision: decision,
      storedAt: timestamp,
      notificationDispatched: notificationDispatched,
      dispatchFailure: dispatchFailure,
    );
  }

  factory AlertDecisionRecord.fromJson(Map<String, dynamic> json) {
    return AlertDecisionRecord(
      id: json['id']?.toString() ?? '',
      decision: HealthAlertDecision.fromJson(_stringMap(json['decision'])),
      storedAt:
          DateTime.tryParse(json['stored_at']?.toString() ?? '') ??
          DateTime.now(),
      notificationDispatched: json['notification_dispatched'] == true,
      dispatchFailure: json['dispatch_failure']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'decision': decision.toJson(),
    'stored_at': storedAt.toIso8601String(),
    'notification_dispatched': notificationDispatched,
    if (dispatchFailure != null) 'dispatch_failure': dispatchFailure,
  };
}

Map<String, dynamic> _stringMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

num? _numValue(dynamic value) {
  if (value is num && value is! bool) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

class UrgentCarePatientStatus {
  const UrgentCarePatientStatus({
    required this.localPatientId,
    required this.patientId,
    required this.status,
    required this.patientsAhead,
    required this.estimatedWaitRange,
    required this.submittedInformation,
    this.queueNumber,
    this.notified = false,
    this.notifiedAt,
    this.checkedInAt,
    this.serverTime,
    this.accessToken,
  });

  final int localPatientId;
  final int patientId;
  final int? queueNumber;
  final String status;
  final int patientsAhead;
  final String estimatedWaitRange;
  final bool notified;
  final String? notifiedAt;
  final String? checkedInAt;
  final String? serverTime;
  final String? accessToken;
  final Map<String, dynamic> submittedInformation;

  bool get isFinished => status.toLowerCase().contains('completed');

  bool get isCalled =>
      notified || status.toLowerCase().contains('consultation');

  factory UrgentCarePatientStatus.fromJson(Map<String, dynamic> json) {
    return UrgentCarePatientStatus(
      localPatientId: _asInt(json['local_patient_id']),
      patientId: _asInt(json['patient_id']),
      queueNumber: json['queue_number'] == null
          ? null
          : _asInt(json['queue_number']),
      status: json['status']?.toString() ?? 'Waiting',
      patientsAhead: _asInt(json['patients_ahead']),
      estimatedWaitRange:
          json['estimated_wait_range']?.toString() ?? 'Not available',
      notified: json['notified'] == true,
      notifiedAt: json['notified_at']?.toString(),
      checkedInAt: json['checked_in_at']?.toString(),
      serverTime: json['server_time']?.toString(),
      accessToken: json['access_token']?.toString(),
      submittedInformation: Map<String, dynamic>.from(
        json['submitted_information'] as Map? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'local_patient_id': localPatientId,
    'patient_id': patientId,
    'queue_number': queueNumber,
    'status': status,
    'patients_ahead': patientsAhead,
    'estimated_wait_range': estimatedWaitRange,
    'notified': notified,
    'notified_at': notifiedAt,
    'checked_in_at': checkedInAt,
    'server_time': serverTime,
    'access_token': accessToken,
    'submitted_information': submittedInformation,
  };

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class UrgentCareCheckInResult {
  const UrgentCareCheckInResult({
    required this.message,
    required this.patient,
    required this.analysis,
  });

  final String message;
  final UrgentCarePatientStatus patient;
  final Map<String, dynamic> analysis;

  factory UrgentCareCheckInResult.fromJson(Map<String, dynamic> json) {
    return UrgentCareCheckInResult(
      message: json['message']?.toString() ?? 'Check-in complete.',
      patient: UrgentCarePatientStatus.fromJson(
        Map<String, dynamic>.from(json['patient'] as Map? ?? {}),
      ),
      analysis: Map<String, dynamic>.from(json['analysis'] as Map? ?? {}),
    );
  }
}

class UrgentCareFeedbackResult {
  const UrgentCareFeedbackResult({
    required this.message,
    required this.alertRequired,
  });

  final String message;
  final bool alertRequired;

  factory UrgentCareFeedbackResult.fromJson(Map<String, dynamic> json) {
    final alert = Map<String, dynamic>.from(json['alert_agent'] as Map? ?? {});
    return UrgentCareFeedbackResult(
      message:
          json['message']?.toString() ??
          alert['patient_message']?.toString() ??
          'Your update was submitted.',
      alertRequired: alert['alert_required'] == true,
    );
  }
}

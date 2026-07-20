import 'dart:typed_data';

enum ReportSessionStatus { fresh, analyzing, complete, error }

class ReportChatMessage {
  const ReportChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    this.isFile = false,
    this.fileName,
    this.labValues = const [],
  });

  final String sender;
  final String text;
  final DateTime timestamp;
  final bool isFile;
  final String? fileName;
  final List<LabValueVisual> labValues;

  bool get isUser => sender == 'user';
}

class LabValueVisual {
  const LabValueVisual({
    required this.name,
    required this.value,
    required this.normalMin,
    required this.normalMax,
    required this.status,
    this.unit = '',
    this.display,
  });

  final String name;
  final double value;
  final double normalMin;
  final double normalMax;
  final String unit;
  final String status;
  final String? display;

  factory LabValueVisual.fromJson(Map<String, dynamic> json) {
    double readDouble(String key) {
      final raw = json[key];
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw?.toString() ?? '') ?? 0;
    }

    return LabValueVisual(
      name: json['name']?.toString() ?? 'Lab value',
      value: readDouble('value'),
      normalMin: readDouble('normalMin'),
      normalMax: readDouble('normalMax'),
      unit: json['unit']?.toString() ?? '',
      status: json['status']?.toString() ?? 'normal',
      display: json['display']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'normalMin': normalMin,
      'normalMax': normalMax,
      'unit': unit,
      'status': status,
      if (display != null) 'display': display,
    };
  }
}

class ReportSession {
  ReportSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
    this.fileContext,
    this.status = ReportSessionStatus.fresh,
    this.isTyping = false,
    this.suggestedQuestions = const [],
    this.usedSuggestedQuestions = const [],
    this.needsPatientName = false,
    this.pendingLabValues = const [],
    this.pendingReportDate,
    this.pendingDetectedTestType,
  });

  final String id;
  String title;
  DateTime createdAt;
  List<ReportChatMessage> messages;
  String? fileContext;
  ReportSessionStatus status;
  bool isTyping;
  List<String> suggestedQuestions;
  List<String> usedSuggestedQuestions;
  bool needsPatientName;
  List<LabValueVisual> pendingLabValues;
  String? pendingReportDate;
  String? pendingDetectedTestType;

  factory ReportSession.blank() {
    final now = DateTime.now();
    return ReportSession(
      id: now.microsecondsSinceEpoch.toString(),
      title: 'New report',
      createdAt: now,
      messages: [],
    );
  }
}

class PickedReport {
  const PickedReport({
    required this.name,
    this.bytes,
    this.path,
    this.sizeBytes,
  });

  final String name;
  final Uint8List? bytes;
  final String? path;
  final int? sizeBytes;

  bool get hasPath => path != null && path!.isNotEmpty;
}

class TestType {
  const TestType({required this.id, required this.name});

  final String id;
  final String name;

  factory TestType.fromJson(Map<String, dynamic> json) {
    return TestType(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class PatientOption {
  const PatientOption({required this.id, required this.name});

  final String id;
  final String name;

  factory PatientOption.fromJson(Map<String, dynamic> json) {
    final id = json['patient_id']?.toString() ?? json['id']?.toString() ?? '';
    return PatientOption(
      id: id,
      name: json['name']?.toString() ?? 'Patient $id',
    );
  }
}

class AnalyzeReportResult {
  const AnalyzeReportResult({
    required this.analysis,
    required this.labValues,
    required this.patientNameNeeded,
    required this.patientNameQuestion,
    required this.savedLabRecordCount,
    required this.detectedTestType,
    required this.saveErrors,
    this.reportDate,
    this.fileContext,
    this.patient,
  });

  final String analysis;
  final List<LabValueVisual> labValues;
  final bool patientNameNeeded;
  final String patientNameQuestion;
  final int savedLabRecordCount;
  final String detectedTestType;
  final String? reportDate;
  final String? fileContext;
  final List<String> saveErrors;
  final PatientOption? patient;

  factory AnalyzeReportResult.fromJson(Map<String, dynamic> json) {
    final labValues = (json['labValues'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(LabValueVisual.fromJson)
        .where((value) => value.normalMin < value.normalMax)
        .toList();

    return AnalyzeReportResult(
      analysis: json['analysis']?.toString() ?? 'Analysis complete.',
      labValues: labValues,
      patientNameNeeded: json['patientNameNeeded'] == true,
      patientNameQuestion:
          json['patientNameQuestion']?.toString() ??
          'I could not clearly detect the patient name from this report. What is the patient full name?',
      savedLabRecordCount: json['savedLabRecordCount'] as int? ?? 0,
      detectedTestType: json['detectedTestType']?.toString() ?? 'record',
      reportDate: json['reportDate']?.toString(),
      fileContext: json['fileContext']?.toString(),
      saveErrors: (json['saveErrors'] as List<dynamic>? ?? [])
          .map((error) => error.toString())
          .where((error) => error.trim().isNotEmpty)
          .toList(),
      patient: json['patient'] is Map<String, dynamic>
          ? PatientOption.fromJson(json['patient'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AssignPatientResult {
  const AssignPatientResult({
    required this.savedLabRecordCount,
    required this.saveErrors,
    this.patient,
  });

  final int savedLabRecordCount;
  final List<String> saveErrors;
  final PatientOption? patient;

  factory AssignPatientResult.fromJson(Map<String, dynamic> json) {
    return AssignPatientResult(
      savedLabRecordCount: json['savedLabRecordCount'] as int? ?? 0,
      saveErrors: (json['saveErrors'] as List<dynamic>? ?? [])
          .map((error) => error.toString())
          .toList(),
      patient: json['patient'] is Map<String, dynamic>
          ? PatientOption.fromJson(json['patient'] as Map<String, dynamic>)
          : null,
    );
  }
}

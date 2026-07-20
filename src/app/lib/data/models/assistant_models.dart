class TrendInsights {
  final Map<String, String> values;

  const TrendInsights(this.values);
}

class AssistantConversationMessage {
  final String role;
  final String content;

  const AssistantConversationMessage({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class AssistantChatReply {
  final String reply;
  final List<AssistantResult> results;

  const AssistantChatReply({required this.reply, required this.results});

  factory AssistantChatReply.fromJson(Map<String, dynamic> json) {
    final reply = json['reply']?.toString() ?? '';
    final rawResults = json['results'];
    final results = rawResults is List
        ? rawResults
              .whereType<Map>()
              .map(
                (item) =>
                    AssistantResult.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <AssistantResult>[];
    return AssistantChatReply(
      reply: reply,
      results: results.isEmpty
          ? [AssistantTextResult(content: reply)]
          : results,
    );
  }
}

abstract class AssistantResult {
  const AssistantResult();

  String get type;

  Map<String, dynamic> toJson();

  factory AssistantResult.fromJson(Map<String, dynamic> json) {
    switch (json['type']?.toString()) {
      case 'text':
        return AssistantTextResult(content: json['content']?.toString() ?? '');
      case 'chart':
        return AssistantChartResult.fromJson(json);
      case 'report':
        return AssistantReportResult.fromJson(json);
      default:
        return AssistantUnknownResult(raw: json);
    }
  }
}

class AssistantTextResult extends AssistantResult {
  final String content;

  const AssistantTextResult({required this.content});

  @override
  String get type => 'text';

  @override
  Map<String, dynamic> toJson() => {'type': type, 'content': content};
}

class AssistantUnknownResult extends AssistantResult {
  final Map<String, dynamic> raw;

  const AssistantUnknownResult({required this.raw});

  @override
  String get type => 'unknown';

  @override
  Map<String, dynamic> toJson() => raw;
}

class AssistantReportResult extends AssistantResult {
  final String format;
  final String title;
  final String content;
  final DateTime? generatedAt;
  final DateTime? expiresAt;
  final String freshnessReason;
  final String? sourceSummary;

  const AssistantReportResult({
    required this.format,
    required this.title,
    required this.content,
    required this.generatedAt,
    required this.expiresAt,
    required this.freshnessReason,
    this.sourceSummary,
  });

  @override
  String get type => 'report';

  bool get isExpired {
    final expires = expiresAt;
    if (expires == null) return false;
    return DateTime.now().toUtc().isAfter(expires.toUtc());
  }

  factory AssistantReportResult.fromJson(Map<String, dynamic> json) {
    return AssistantReportResult(
      format: json['format']?.toString() ?? 'markdown',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? ''),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
      freshnessReason: json['freshnessReason']?.toString() ?? '',
      sourceSummary: json['sourceSummary']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'format': format,
    'title': title,
    'content': content,
    if (generatedAt != null) 'generatedAt': generatedAt!.toIso8601String(),
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    'freshnessReason': freshnessReason,
    if (sourceSummary != null) 'sourceSummary': sourceSummary,
  };
}

class AssistantChartResult extends AssistantResult {
  static const supportedDisplayTypes = {'line', 'bar'};

  final String displayType;
  final String title;
  final String? subtitle;
  final AssistantChartAxis xAxis;
  final AssistantChartAxis yAxis;
  final List<AssistantChartSeries> series;

  const AssistantChartResult({
    required this.displayType,
    required this.title,
    this.subtitle,
    required this.xAxis,
    required this.yAxis,
    required this.series,
  });

  @override
  String get type => 'chart';

  factory AssistantChartResult.fromJson(Map<String, dynamic> json) {
    final displayType = json['displayType']?.toString() ?? '';
    if (!supportedDisplayTypes.contains(displayType)) {
      return AssistantUnsupportedChartResult(
        displayType: displayType,
        raw: json,
      );
    }
    final rawSeries = json['series'];
    return AssistantChartResult(
      displayType: displayType,
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      xAxis: AssistantChartAxis.fromJson(_asMap(json['xAxis'])),
      yAxis: AssistantChartAxis.fromJson(_asMap(json['yAxis'])),
      series: rawSeries is List
          ? rawSeries
                .whereType<Map>()
                .map(
                  (item) => AssistantChartSeries.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'displayType': displayType,
    'title': title,
    if (subtitle != null) 'subtitle': subtitle,
    'xAxis': xAxis.toJson(),
    'yAxis': yAxis.toJson(),
    'series': series.map((item) => item.toJson()).toList(),
  };
}

class AssistantUnsupportedChartResult extends AssistantChartResult {
  final Map<String, dynamic> raw;

  AssistantUnsupportedChartResult({
    required String displayType,
    required this.raw,
  }) : super(
         displayType: displayType,
         title: raw['title']?.toString() ?? '',
         xAxis: const AssistantChartAxis(label: ''),
         yAxis: const AssistantChartAxis(label: ''),
         series: const [],
       );

  @override
  Map<String, dynamic> toJson() => raw;
}

class AssistantChartAxis {
  final String label;
  final String? type;
  final String? unit;

  const AssistantChartAxis({required this.label, this.type, this.unit});

  factory AssistantChartAxis.fromJson(Map<String, dynamic> json) {
    return AssistantChartAxis(
      label: json['label']?.toString() ?? '',
      type: json['type']?.toString(),
      unit: json['unit']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    if (type != null) 'type': type,
    if (unit != null) 'unit': unit,
  };
}

class AssistantChartSeries {
  final String name;
  final List<AssistantChartPoint> points;

  const AssistantChartSeries({required this.name, required this.points});

  factory AssistantChartSeries.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'];
    return AssistantChartSeries(
      name: json['name']?.toString() ?? '',
      points: rawPoints is List
          ? rawPoints
                .whereType<Map>()
                .map(
                  (item) => AssistantChartPoint.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'points': points.map((item) => item.toJson()).toList(),
  };
}

class AssistantChartPoint {
  final Object x;
  final double y;
  final String? label;
  final Map<String, dynamic> metadata;

  const AssistantChartPoint({
    required this.x,
    required this.y,
    this.label,
    this.metadata = const {},
  });

  factory AssistantChartPoint.fromJson(Map<String, dynamic> json) {
    return AssistantChartPoint(
      x: json['x'] ?? '',
      y: _toDouble(json['y']),
      label: json['label']?.toString(),
      metadata: _asMap(json['metadata']),
    );
  }

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    if (label != null) 'label': label,
    if (metadata.isNotEmpty) 'metadata': metadata,
  };
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class TrainingRecord {
  final String? workoutId;
  final String? patientId;
  final String workoutType;
  final String? workoutTypeRaw;
  final String? sourceProvider;
  final String? sourceWorkoutId;
  final DateTime? startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final double? distanceMeters;
  final double? activeEnergyKcal;
  final int? steps;

  const TrainingRecord({
    this.workoutId,
    this.patientId,
    required this.workoutType,
    this.workoutTypeRaw,
    this.sourceProvider,
    this.sourceWorkoutId,
    this.startTime,
    this.endTime,
    required this.durationSeconds,
    this.distanceMeters,
    this.activeEnergyKcal,
    this.steps,
  });

  factory TrainingRecord.fromJson(Map<String, dynamic> json) {
    final start = _parseDate(json['start_time'] ?? json['startTime']);
    final end = _parseDate(json['end_time'] ?? json['endTime']);
    final derivedDuration = start != null && end != null
        ? end.difference(start).inSeconds
        : 0;
    final rawDuration = _parseInt(
      json['duration_seconds'] ?? json['durationSeconds'],
    );
    return TrainingRecord(
      workoutId: _readString(json['workout_id'] ?? json['workoutId']),
      patientId: _readString(json['patient_id'] ?? json['patientId']),
      workoutType:
          _readString(json['workout_type'] ?? json['workoutType']) ?? 'workout',
      workoutTypeRaw: _readString(
        json['workout_type_raw'] ?? json['workoutTypeRaw'],
      ),
      sourceProvider: _readString(
        json['source_provider'] ?? json['sourceProvider'],
      ),
      sourceWorkoutId: _readString(
        json['source_workout_id'] ?? json['sourceWorkoutId'],
      ),
      startTime: start,
      endTime: end,
      durationSeconds:
          rawDuration ?? (derivedDuration < 0 ? 0 : derivedDuration),
      distanceMeters: _parseDouble(
        json['distance_meters'] ?? json['distanceMeters'],
      ),
      activeEnergyKcal: _parseDouble(
        json['active_energy_kcal'] ??
            json['activeEnergyKcal'] ??
            json['total_energy_kcal'] ??
            json['totalEnergyKcal'],
      ),
      steps: _parseInt(json['steps']),
    );
  }

  String get stableKey {
    final source = sourceProvider?.trim();
    final sourceId = sourceWorkoutId?.trim();
    if (source != null &&
        source.isNotEmpty &&
        sourceId != null &&
        sourceId.isNotEmpty) {
      return '$source::$sourceId';
    }
    if (workoutId != null && workoutId!.trim().isNotEmpty) {
      return 'workout::$workoutId';
    }
    return '${workoutType}_${startTime?.toIso8601String() ?? ''}_$durationSeconds';
  }

  String get displayType {
    final cleaned = workoutType.replaceAll('_', ' ').trim();
    if (cleaned.isEmpty) return 'Workout';
    return cleaned
        .split(RegExp(r'\s+'))
        .map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        })
        .join(' ');
  }

  static List<TrainingRecord> sortDedupeAndLimit(
    Iterable<TrainingRecord> records, {
    int limit = 30,
  }) {
    final deduped = <String, TrainingRecord>{};
    for (final record in records) {
      deduped.putIfAbsent(record.stableKey, () => record);
    }
    final sorted = deduped.values.toList()
      ..sort((a, b) {
        final aTime = a.startTime;
        final bTime = b.startTime;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
    return sorted.take(limit).toList();
  }

  static String? _readString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static DateTime? _parseDate(dynamic value) {
    final text = _readString(value);
    if (text == null) return null;
    return DateTime.tryParse(text);
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

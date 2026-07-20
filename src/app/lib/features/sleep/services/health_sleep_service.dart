import 'package:health/health.dart';
import '../models/night_sleep.dart';

/// Reads real sleep data from Apple HealthKit (sourced from a paired Apple Watch):
/// sleep stages (deep, REM, core/light, awake), blood oxygen (SpO2), and heart rate.
/// Groups the raw samples into per-night summaries the UI and backend consume.
class HealthSleepService {
  final Health _health = Health();

  static const _types = <HealthDataType>[
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.HEART_RATE,
  ];

  /// Ask the user for read access to the sleep-related HealthKit types.
  Future<bool> requestPermissions() async {
    await _health.configure();
    final permissions = _types.map((_) => HealthDataAccess.READ).toList();
    // hasPermissions can return null on iOS; fall back to requesting.
    final already = await _health.hasPermissions(
      _types,
      permissions: permissions,
    );
    if (already == true) return true;
    return _health.requestAuthorization(_types, permissions: permissions);
  }

  /// Fetch the last [nights] nights of sleep and roll them up per night.
  /// A "sleep night" is keyed by the calendar date the sleep session started.
  Future<List<NightSleep>> fetchNightlySleep({int nights = 7}) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: nights + 1));

    final raw = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: now,
      types: _types,
    );
    final points = _health.removeDuplicates(raw);

    // Accumulators keyed by night (yyyy-MM-dd).
    final deep = <String, double>{};
    final rem = <String, double>{};
    final core = <String, double>{};
    final awake = <String, double>{};
    final asleep = <String, double>{};
    final inBed = <String, double>{};
    final spo2 = <String, List<double>>{};
    final hr = <String, List<double>>{};

    void addMinutes(
      Map<String, double> map,
      String night,
      DateTime a,
      DateTime b,
    ) {
      final minutes = b.difference(a).inSeconds / 60.0;
      map[night] = (map[night] ?? 0) + (minutes < 0 ? 0 : minutes);
    }

    for (final p in points) {
      final night = _nightKey(p.dateFrom);
      switch (p.type) {
        case HealthDataType.SLEEP_DEEP:
          addMinutes(deep, night, p.dateFrom, p.dateTo);
          addMinutes(asleep, night, p.dateFrom, p.dateTo);
          break;
        case HealthDataType.SLEEP_REM:
          addMinutes(rem, night, p.dateFrom, p.dateTo);
          addMinutes(asleep, night, p.dateFrom, p.dateTo);
          break;
        case HealthDataType.SLEEP_LIGHT:
        case HealthDataType.SLEEP_ASLEEP:
          addMinutes(core, night, p.dateFrom, p.dateTo);
          addMinutes(asleep, night, p.dateFrom, p.dateTo);
          break;
        case HealthDataType.SLEEP_AWAKE:
          addMinutes(awake, night, p.dateFrom, p.dateTo);
          break;
        case HealthDataType.SLEEP_IN_BED:
          addMinutes(inBed, night, p.dateFrom, p.dateTo);
          break;
        case HealthDataType.BLOOD_OXYGEN:
          final v = _numeric(p.value);
          if (v != null) (spo2[night] ??= []).add(v <= 1 ? v * 100 : v);
          break;
        case HealthDataType.HEART_RATE:
          final v = _numeric(p.value);
          if (v != null) (hr[night] ??= []).add(v);
          break;
        default:
          break;
      }
    }

    final allNights = <String>{
      ...deep.keys,
      ...rem.keys,
      ...core.keys,
      ...awake.keys,
      ...asleep.keys,
    }.toList()..sort();

    double? avg(List<double>? xs) => (xs == null || xs.isEmpty)
        ? null
        : xs.reduce((a, b) => a + b) / xs.length;
    double? lo(List<double>? xs) =>
        (xs == null || xs.isEmpty) ? null : xs.reduce((a, b) => a < b ? a : b);

    final result = <NightSleep>[];
    for (final night in allNights) {
      final a = asleep[night] ?? 0;
      final ib = inBed[night] ?? (a + (awake[night] ?? 0));
      result.add(
        NightSleep(
          night: night,
          deepMinutes: deep[night] ?? 0,
          remMinutes: rem[night] ?? 0,
          coreMinutes: core[night] ?? 0,
          lightMinutes: 0,
          awakeMinutes: awake[night] ?? 0,
          asleepMinutes: a,
          inBedMinutes: ib,
          spo2Avg: avg(spo2[night]),
          spo2Min: lo(spo2[night]),
          hrAvg: avg(hr[night]),
          hrMin: lo(hr[night]),
          source: 'apple_health',
        ),
      );
    }

    // Keep only the most recent [nights] with actual sleep recorded.
    final withSleep = result.where((n) => n.asleepMinutes > 0).toList();
    if (withSleep.length > nights) {
      return withSleep.sublist(withSleep.length - nights);
    }
    return withSleep;
  }

  /// A sleep session that starts after midnight (e.g. 1am) still belongs to the
  /// previous evening's "night"; anything before 6pm is bucketed to that date.
  String _nightKey(DateTime start) {
    final local = start.toLocal();
    final d = local.hour < 18 ? local.subtract(const Duration(days: 1)) : local;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  double? _numeric(HealthValue value) {
    if (value is NumericHealthValue) return value.numericValue.toDouble();
    return null;
  }
}

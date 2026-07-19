class NightSleep {
  final String night;
  final double deepMinutes;
  final double remMinutes;
  final double coreMinutes;
  final double lightMinutes;
  final double awakeMinutes;
  final double asleepMinutes;
  final double inBedMinutes;
  final double? spo2Avg;
  final double? spo2Min;
  final double? hrAvg;
  final double? hrMin;
  final String source;

  NightSleep({
    required this.night,
    required this.deepMinutes,
    required this.remMinutes,
    required this.coreMinutes,
    required this.lightMinutes,
    required this.awakeMinutes,
    required this.asleepMinutes,
    required this.inBedMinutes,
    this.spo2Avg,
    this.spo2Min,
    this.hrAvg,
    this.hrMin,
    this.source = 'apple_health',
  });

  String get nightIso => night;
}

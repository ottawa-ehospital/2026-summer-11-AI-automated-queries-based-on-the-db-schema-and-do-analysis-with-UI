import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/widgets/widgets.dart';
import '../../../services/e_hospital_service.dart';
import '../../../l10n/l10n.dart';
import '../../../ui/app_theme.dart';
import '../presentation/insights_styles.dart';
import '../widgets/health_insight_card.dart';
import '../widgets/insight_chip.dart';
import '../widgets/insight_correlation_row.dart';
import '../widgets/insight_disclaimer_banner.dart';
import '../widgets/insight_legend_dot.dart';
import '../widgets/insight_section_card.dart';
import '../widgets/insight_summary_section.dart';
import '../widgets/insight_threshold_chip.dart';
import '../widgets/insights_analysis_header.dart';
import '../widgets/insights_count_header.dart';
import '../widgets/insights_medical_footer.dart';

class HealthInsightsScreen extends StatefulWidget {
  const HealthInsightsScreen({Key? key}) : super(key: key);

  @override
  State<HealthInsightsScreen> createState() => _HealthInsightsScreenState();
}

class _HealthInsightsScreenState extends State<HealthInsightsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _insights = [];

  // Raw table data
  List<dynamic> _wearableVitals = [];
  List<dynamic> _diabetesData = [];
  List<dynamic> _ecgData = [];
  List<dynamic> _heartDiseaseData = [];
  List<dynamic> _strokeData = [];
  List<dynamic> _labTestsData = [];
  List<dynamic> _diagnosisData = [];
  List<dynamic> _vitalsHistoryData = [];

  // NEW analytics state
  List<Map<String, dynamic>> _mergedRecords = []; // timestamp-matched pairs
  double? _corrStepsCalories; // Pearson r
  double? _corrHrBp; // Pearson r wearable HR vs clinical BP
  List<Map<String, dynamic>> _anomalyAlerts = []; // rule-based anomaly table
  List<Map<String, dynamic>> _allPatientsStats = []; // multi-patient comparison

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  // DATA LOADING

  Future<void> _loadInsights() async {
    final prefs = await SharedPreferences.getInstance();
    final Object? rawId = prefs.get('patient_id');
    if (rawId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final patientId = int.tryParse(rawId.toString());
    if (patientId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // Fetch all wearable vitals (needed for multi-patient + per-patient)
    final allWearable = await EHospitalService.fetchVitals();
    final wearableVitals = allWearable.where((e) {
      final id = e["patient_id"];
      if (id == null) return false;
      return id is int
          ? id == patientId
          : id.toString() == patientId.toString();
    }).toList();

    // Fetch clinical tables in parallel
    final results = await Future.wait([
      _fetchTableForPatient("ecg", patientId),
      _fetchTableForPatient("diabetes_analysis", patientId),
      _fetchTableForPatient("heart_disease_analysis", patientId),
      _fetchTableForPatient("stroke_prediction", patientId),
      _fetchTableForPatient("lab_tests", patientId),
      _fetchTableForPatient("diagnosis", patientId),
      _fetchTableForPatient("vitals_history", patientId),
    ]);

    final ecgList = results[0];
    final diabetes = results[1];
    final heartDisease = results[2];
    final strokeData = results[3];
    final labTests = results[4];
    final diagnosis = results[5];
    final vitalsHistory = results[6];

    // Rule-based + Z-score insights (existing)
    final insights = _generateInsights(
      wearableVitals,
      ecgList,
      diabetes,
      heartDisease,
      strokeData,
      labTests,
      diagnosis,
    );

    // NEW: Timestamp-based merging
    final mergedRecords = _mergeByTimestamp(wearableVitals, vitalsHistory);

    // NEW: Pearson Correlation
    final corrStepsCalories = _corrStepsCaloriesFn(wearableVitals);
    final corrHrBp = _corrHrBpFn(mergedRecords);

    // NEW: Rule-based anomaly table
    final anomalyAlerts = _computeAnomalyAlerts(vitalsHistory);

    // NEW: Multi-patient stats
    final allPatientsStats = _computeAllPatientsStats(allWearable, patientId);

    if (mounted) {
      setState(() {
        _insights = insights;
        _wearableVitals = wearableVitals;
        _diabetesData = diabetes;
        _ecgData = ecgList;
        _heartDiseaseData = heartDisease;
        _strokeData = strokeData;
        _labTestsData = labTests;
        _diagnosisData = diagnosis;
        _vitalsHistoryData = vitalsHistory;
        _mergedRecords = mergedRecords;
        _corrStepsCalories = corrStepsCalories;
        _corrHrBp = corrHrBp;
        _anomalyAlerts = anomalyAlerts;
        _allPatientsStats = allPatientsStats;
        _loading = false;
      });
    }
  }

  Future<List<dynamic>> _fetchTableForPatient(
    String table,
    int patientId,
  ) async {
    try {
      return EHospitalService.fetchTable(
        table,
        patientId: patientId.toString(),
      );
    } catch (_) {
      return [];
    }
  }

  // ANALYTICS FUNCTIONS

  /// Parse ISO timestamp (handles missing / invalid)
  DateTime? _parseTimestamp(String s) {
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  /// Merge wearable + clinical vitals by closest timestamp within [window]
  /// Returns list of {wearable, clinical, timeDiffHours}
  List<Map<String, dynamic>> _mergeByTimestamp(
    List<dynamic> wearable,
    List<dynamic> vitalsHistory, {
    Duration window = const Duration(hours: 48),
  }) {
    final merged = <Map<String, dynamic>>[];
    for (final w in wearable) {
      final wTs = _parseTimestamp(w["timestamp"]?.toString() ?? "");
      if (wTs == null) continue;

      Map<String, dynamic>? bestMatch;
      Duration bestDiff = window + const Duration(seconds: 1);

      for (final v in vitalsHistory) {
        final vTs = _parseTimestamp(v["recorded_on"]?.toString() ?? "");
        if (vTs == null) continue;
        final diff = wTs.difference(vTs).abs();
        if (diff <= window && diff < bestDiff) {
          bestDiff = diff;
          bestMatch = Map<String, dynamic>.from(v);
        }
      }

      if (bestMatch != null) {
        merged.add({
          "wearable": Map<String, dynamic>.from(w),
          "clinical": bestMatch,
          "timeDiffHours": bestDiff.inHours,
        });
      }
    }
    return merged;
  }

  /// Pearson correlation coefficient for two equal-length lists (>=2 points)
  double? _pearsonR(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 2) return null;
    final n = x.length;
    final meanX = x.reduce((a, b) => a + b) / n;
    final meanY = y.reduce((a, b) => a + b) / n;
    double num = 0, sumX2 = 0, sumY2 = 0;
    for (int i = 0; i < n; i++) {
      num += (x[i] - meanX) * (y[i] - meanY);
      sumX2 += math.pow(x[i] - meanX, 2);
      sumY2 += math.pow(y[i] - meanY, 2);
    }
    final denom = math.sqrt(sumX2 * sumY2);
    return denom == 0 ? null : num / denom;
  }

  /// Pearson r: Steps vs Calories from wearable data
  double? _corrStepsCaloriesFn(List<dynamic> wearable) {
    final steps = <double>[];
    final calories = <double>[];
    for (final w in wearable) {
      final s = _toDouble(w["steps"]);
      final c = _toDouble(w["calories"] ?? w["calories_burned"]);
      if (s > 0 && c > 0) {
        steps.add(s);
        calories.add(c);
      }
    }
    return _pearsonR(steps, calories);
  }

  /// Pearson r: Wearable HR vs Clinical systolic BP from merged records
  double? _corrHrBpFn(List<Map<String, dynamic>> merged) {
    final hrs = <double>[];
    final sbps = <double>[];
    for (final m in merged) {
      final hr = _toDouble((m["wearable"] as Map)["heart_rate"]);
      final sbp = _parseSystolic(
        (m["clinical"] as Map)["blood_pressure"]?.toString() ?? "",
      ).toDouble();
      if (hr > 0 && sbp > 0) {
        hrs.add(hr);
        sbps.add(sbp);
      }
    }
    return _pearsonR(hrs, sbps);
  }

  /// Parse "120/80" -> 120 (systolic).
  int _parseSystolic(String bp) {
    try {
      final parts = bp.split("/");
      return int.tryParse(parts[0].trim()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Parse "120/80" -> 80 (diastolic).
  int _parseDiastolic(String bp) {
    try {
      final parts = bp.split("/");
      if (parts.length < 2) return 0;
      return int.tryParse(parts[1].trim()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Rule-based anomaly detection from clinical vitals_history
  List<Map<String, dynamic>> _computeAnomalyAlerts(
    List<dynamic> vitalsHistory,
  ) {
    final alerts = <Map<String, dynamic>>[];
    for (final v in vitalsHistory) {
      final date = _formatShortDate(v["recorded_on"]?.toString() ?? "");

      // HR < 40 or > 140
      final hr = _toDouble(v["heart_rate"]);
      if (hr > 0 && (hr < 40 || hr > 140)) {
        alerts.add({
          "metric": "Heart Rate",
          "value": "${hr.toInt()} bpm",
          "threshold": hr < 40 ? "< 40 bpm" : "> 140 bpm",
          "date": date,
          "critical": hr < 40 || hr > 150,
        });
      }

      // BP > 140/90
      final bpStr = v["blood_pressure"]?.toString() ?? "";
      final sys = _parseSystolic(bpStr);
      final dia = _parseDiastolic(bpStr);
      if (sys > 140 || dia > 90) {
        alerts.add({
          "metric": "Blood Pressure",
          "value": bpStr,
          "threshold": "< 140/90 mmHg",
          "date": date,
          "critical": sys > 160 || dia > 100,
        });
      }

      // Temperature > 38deg C
      final temp = _toDouble(v["temperature"]);
      if (temp > 38.0) {
        alerts.add({
          "metric": "Temperature",
          "value": "${temp.toStringAsFixed(1)} deg C",
          "threshold": ">=38.0 deg C",
          "date": date,
          "critical": temp > 39.5,
        });
      }
    }
    return alerts;
  }

  /// Group all wearable records by patient_id, compute avg steps + avg HR
  List<Map<String, dynamic>> _computeAllPatientsStats(
    List<dynamic> allWearable,
    int currentPatientId,
  ) {
    final groups = <String, List<dynamic>>{};
    for (final w in allWearable) {
      final id = w["patient_id"]?.toString() ?? "?";
      groups.putIfAbsent(id, () => []).add(w);
    }

    final stats = <Map<String, dynamic>>[];
    for (final entry in groups.entries) {
      final records = entry.value;
      final avgSteps = records.isEmpty
          ? 0.0
          : records.map((r) => _toDouble(r["steps"])).reduce((a, b) => a + b) /
                records.length;
      final avgHR = records.isEmpty
          ? 0.0
          : records
                    .map((r) => _toDouble(r["heart_rate"]))
                    .reduce((a, b) => a + b) /
                records.length;
      final avgCal = records.isEmpty
          ? 0.0
          : records
                    .map(
                      (r) => _toDouble(r["calories"] ?? r["calories_burned"]),
                    )
                    .reduce((a, b) => a + b) /
                records.length;
      stats.add({
        "patient_id": entry.key,
        "is_current": entry.key == currentPatientId.toString(),
        "count": records.length,
        "avg_steps": avgSteps,
        "avg_hr": avgHR,
        "avg_cal": avgCal,
      });
    }

    stats.sort(
      (a, b) => (b["avg_steps"] as double).compareTo(a["avg_steps"] as double),
    );
    return stats.take(8).toList();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  // INSIGHTS GENERATION (existing rules + new BP/Temp rules)

  List<Map<String, dynamic>> _generateInsights(
    List<dynamic> wearableVitals,
    List<dynamic> ecgList,
    List<dynamic> diabetes,
    List<dynamic> heartDisease,
    List<dynamic> strokeData,
    List<dynamic> labTests,
    List<dynamic> diagnosis,
  ) {
    final insights = <Map<String, dynamic>>[];

    double avgHR = 0;
    int maxHR = 0;
    int hrSpikeCount = 0;
    if (wearableVitals.isNotEmpty) {
      double total = 0;
      for (final v in wearableVitals) {
        final hr = _toDouble(v["heart_rate"]).toInt();
        total += hr;
        if (hr > maxHR) maxHR = hr;
        if (hr > 100) hrSpikeCount++;
      }
      avgHR = total / wearableVitals.length;
    }

    // Rule 1: Extreme wearable HR (< 40 or > 140)
    final criticalHR = wearableVitals.where((v) {
      final hr = _toDouble(v["heart_rate"]);
      return hr > 0 && (hr < 40 || hr > 140);
    }).toList();
    if (criticalHR.isNotEmpty) {
      insights.add({
        "severity": "critical",
        "title": "Heart Rate Wellness Alert",
        "description":
            "${criticalHR.length} wearable reading(s) show HR outside the typical wellness range (< 40 or > 140 bpm). "
            "Please consult your healthcare provider to discuss these readings.",
        "sources": "Wearable (Rule-Based)",
      });
    }

    // Rule 2: Elevated wearable HR + abnormal ECG
    final abnormalEcg = ecgList.where((e) {
      final result = e["ecg_result"]?.toString().toLowerCase() ?? "";
      return result.contains("abnormal") ||
          result.contains("atrial") ||
          result.contains("fibrillation") ||
          result.contains("tachycardia") ||
          result.contains("bradycardia");
    }).toList();

    if (avgHR > 100 && abnormalEcg.isNotEmpty) {
      insights.add({
        "severity": "critical",
        "title": "Heart Rate & ECG Wellness Indicators",
        "description":
            "Wearable average HR ${avgHR.toStringAsFixed(0)} bpm + "
            "${abnormalEcg.length} ECG record(s) showing non-standard results. "
            "These wellness indicators may warrant discussion with your healthcare provider.",
        "sources": "Wearable + ECG",
      });
    } else if (avgHR > 100 && ecgList.isNotEmpty) {
      insights.add({
        "severity": "warning",
        "title": "Elevated Wearable Heart Rate",
        "description":
            "Average wearable HR ${avgHR.toStringAsFixed(0)} bpm. ECG on file appears within normal range. "
            "Consider discussing persistent elevated readings with your healthcare provider.",
        "sources": "Wearable + ECG",
      });
    }

    // Rule 3: Wearable HR + low glucose
    final lowGlucose = diabetes.where((e) {
      final g = _toDouble(e["glucose_level"]);
      return g > 0 && g < 70;
    }).toList();
    if (avgHR > 90 && lowGlucose.isNotEmpty) {
      insights.add({
        "severity": "warning",
        "title": "Heart Rate & Glucose Wellness Indicators",
        "description":
            "Wearable HR ${avgHR.toStringAsFixed(0)} bpm + "
            "${lowGlucose.length} glucose reading(s) below 70 mg/dL. "
            "These wellness indicators are worth discussing with your healthcare provider.",
        "sources": "Wearable + Glucose Wellness",
      });
    }

    // Rule 4: High heart health risk indicators
    final highRiskHD = heartDisease
        .where((e) => _toDouble(e["risk_score"]) > 0.7)
        .toList();
    if (highRiskHD.isNotEmpty) {
      final topRisk = highRiskHD
          .map((e) => _toDouble(e["risk_score"]))
          .reduce((a, b) => a > b ? a : b);
      insights.add({
        "severity": avgHR > 90 ? "critical" : "warning",
        "title": "Heart Health Wellness Indicators",
        "description":
            "${highRiskHD.length} record(s) with elevated indicators > 70% (highest: ${(topRisk * 100).toStringAsFixed(0)}%). "
            "${avgHR > 90 ? "Combined with elevated wearable HR (${avgHR.toStringAsFixed(0)} bpm). Please consult your healthcare provider." : "Consider discussing lifestyle and follow-up with your healthcare provider."}",
        "sources": "Heart Health Indicators${avgHR > 90 ? " + Wearable" : ""}",
      });
    }

    // Rule 5: Stroke risk indicators
    final highStroke = strokeData
        .where((e) => _toDouble(e["risk_score"]) >= 0.5)
        .toList();
    if (highStroke.isNotEmpty) {
      final maxRisk = highStroke
          .map((e) => _toDouble(e["risk_score"]))
          .reduce((a, b) => a > b ? a : b);
      insights.add({
        "severity": maxRisk >= 0.7 ? "critical" : "warning",
        "title": "Elevated Stroke Risk Indicators",
        "description":
            "${highStroke.length} record(s) with elevated indicators >=50% (highest: ${(maxRisk * 100).toStringAsFixed(0)}%). "
            "${hrSpikeCount > 0 ? "$hrSpikeCount wearable HR spike(s) also noted. Please consult your healthcare provider promptly." : "Please consult your healthcare provider to discuss these wellness indicators."}",
        "sources":
            "Stroke Risk Indicators${hrSpikeCount > 0 ? " + Wearable" : ""}",
      });
    }

    // Rule 6: Abnormal lab tests
    final abnormalLabs = labTests.where((e) {
      final s = e["status"]?.toString().toLowerCase() ?? "";
      return s.contains("abnormal") ||
          s.contains("critical") ||
          s.contains("high") ||
          s.contains("low");
    }).toList();
    if (abnormalLabs.isNotEmpty) {
      final types = abnormalLabs
          .map((e) => e["test_type"]?.toString() ?? "Unknown")
          .toSet()
          .take(3)
          .join(", ");
      insights.add({
        "severity": "warning",
        "title": "Lab Test Wellness Indicators",
        "description":
            "${abnormalLabs.length} lab test(s) show non-standard results (e.g. $types). "
            "${avgHR > 90 ? "Combined with wearable HR ${avgHR.toStringAsFixed(0)} bpm. Please consult your healthcare provider." : "Please review these results with your healthcare provider."}",
        "sources": "Lab Tests${avgHR > 90 ? " + Wearable" : ""}",
      });
    }

    // Rule 7: Diabetes prediction
    final diabetesPredicted = diabetes.where((e) {
      final pred = e["prediction"]?.toString().toLowerCase() ?? "";
      return pred == "positive" ||
          pred == "1" ||
          pred == "diabetic" ||
          pred.contains("high");
    }).toList();
    if (diabetesPredicted.isNotEmpty && lowGlucose.isEmpty) {
      insights.add({
        "severity": "warning",
        "title": "Glucose Wellness Indicators",
        "description":
            "${diabetesPredicted.length} glucose wellness record(s) show elevated indicators. "
            "Please consult your healthcare provider about regular monitoring and healthy lifestyle habits.",
        "sources": "Glucose Wellness",
      });
    }

    // Rule 8: Z-score anomaly on wearable HR
    if (wearableVitals.length >= 3) {
      final hrValues = wearableVitals
          .map((v) => _toDouble(v["heart_rate"]))
          .where((hr) => hr > 0)
          .toList();
      if (hrValues.length >= 3) {
        final mean = hrValues.reduce((a, b) => a + b) / hrValues.length;
        final variance =
            hrValues
                .map((hr) => math.pow(hr - mean, 2))
                .reduce((a, b) => a + b) /
            hrValues.length;
        final std = math.sqrt(variance);
        if (std > 0) {
          final anomalyCount = hrValues
              .where((hr) => (hr - mean) / std > 2.0)
              .length;
          if (anomalyCount > 0) {
            insights.add({
              "severity": "warning",
              "title": "Statistical HR Anomaly (Z-Score > 2σ)",
              "description":
                  "$anomalyCount reading(s) exceed 2 standard deviations above mean HR "
                  "(${mean.toStringAsFixed(0)} bpm, σ=${std.toStringAsFixed(1)}). "
                  "These outliers may indicate stress events or sensor artifacts.",
              "sources": "Wearable (Z-Score Analysis)",
            });
          }
        }
      }
    }

    if (insights.isEmpty) {
      insights.add({
        "severity": "normal",
        "title": "All Indicators Within Normal Range",
        "description":
            "No significant anomalies detected across wearable and clinical records. "
            "Continue healthy habits and schedule routine check-ups.",
        "sources": "Wearable + Clinical Records",
      });
    }

    return insights;
  }

  // NEW SECTION: Wearable vs Clinical HR Comparison Chart

  Widget _buildComparisonChartSection() {
    // Show avg bars if fewer than 2 merged pairs
    if (_mergedRecords.isEmpty && _vitalsHistoryData.isEmpty)
      return const SizedBox.shrink();

    Widget chart;
    String subtitle;

    final wearableHRList = _mergedRecords
        .map((m) => _toDouble((m["wearable"] as Map)["heart_rate"]))
        .where((v) => v > 0)
        .toList();
    final clinicalHRList = _mergedRecords
        .map((m) => _toDouble((m["clinical"] as Map)["heart_rate"]))
        .where((v) => v > 0)
        .toList();

    if (_mergedRecords.length >= 2 &&
        wearableHRList.length >= 2 &&
        clinicalHRList.length >= 2) {
      // Line chart: wearable HR (purple) vs clinical HR (blue)
      subtitle =
          "${_mergedRecords.length} timestamp-matched pairs (+/-48h window)";

      final wSpots = <FlSpot>[];
      final cSpots = <FlSpot>[];
      final pairs = _mergedRecords.take(10).toList();
      for (int i = 0; i < pairs.length; i++) {
        final wHR = _toDouble((pairs[i]["wearable"] as Map)["heart_rate"]);
        final cHR = _toDouble((pairs[i]["clinical"] as Map)["heart_rate"]);
        if (wHR > 0) wSpots.add(FlSpot(i.toDouble(), wHR));
        if (cHR > 0) cSpots.add(FlSpot(i.toDouble(), cHR));
      }

      double maxY = 120;
      for (final s in [...wSpots, ...cSpots]) {
        if (s.y > maxY) maxY = s.y;
      }
      maxY = maxY * 1.2;

      final hasBothLines = wSpots.length >= 2 && cSpots.length >= 2;

      if (hasBothLines) {
        chart = SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 40,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: wSpots,
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 2.5,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withValues(alpha: 0.08),
                  ),
                ),
                if (cSpots.length >= 2)
                  LineChartBarData(
                    spots: cSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 2.5,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withValues(alpha: 0.08),
                    ),
                  ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "P${value.toInt() + 1}",
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) => Text(
                      "${value.toInt()}",
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.15),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        );
      } else {
        chart = _avgComparisonBars();
        subtitle = "Avg wearable HR vs avg clinical HR";
      }
    } else {
      // Fallback: average comparison bars
      chart = _avgComparisonBars();
      subtitle = _mergedRecords.isEmpty
          ? "No overlapping timestamps found - showing averages"
          : "Avg wearable HR vs avg clinical HR";
    }

    return _sectionCard(
      title: "Wearable HR vs Clinical HR",
      subtitle: subtitle,
      icon: Icons.compare_arrows,
      child: Column(
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(AppColors.primary, "Wearable HR"),
              const SizedBox(width: 20),
              _legendDot(Colors.blue, "Clinical HR"),
            ],
          ),
          const SizedBox(height: 12),
          chart,
        ],
      ),
    );
  }

  Widget _avgComparisonBars() {
    final avgWearableHR = _wearableVitals.isEmpty
        ? 0.0
        : _wearableVitals
                  .map((v) => _toDouble(v["heart_rate"]))
                  .reduce((a, b) => a + b) /
              _wearableVitals.length;
    final avgClinicalHR = _vitalsHistoryData.isEmpty
        ? 0.0
        : _vitalsHistoryData
                  .map((v) => _toDouble(v["heart_rate"]))
                  .reduce((a, b) => a + b) /
              _vitalsHistoryData.length;

    final maxY =
        [avgWearableHR, avgClinicalHR, 1.0].reduce((a, b) => a > b ? a : b) *
        1.4;

    return SizedBox(
      height: 150,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, m) {
                  final labels = ["Wearable HR", "Clinical HR"];
                  final i = v.toInt();
                  if (i < 0 || i >= labels.length)
                    return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labels[i],
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: avgWearableHR,
                  color: AppColors.primary,
                  width: 50,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: avgClinicalHR,
                  color: Colors.blue,
                  width: 50,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // NEW SECTION: Pearson Correlation Analysis

  Widget _buildCorrelationSection() {
    if (_corrStepsCalories == null && _corrHrBp == null)
      return const SizedBox.shrink();

    return _sectionCard(
      title: "Correlation Analysis",
      subtitle: "Pearson r coefficient - strength of linear relationship",
      icon: Icons.analytics_outlined,
      child: Column(
        children: [
          if (_corrStepsCalories != null)
            _corrRow(
              label: "Steps -> Calories Burned",
              r: _corrStepsCalories!,
              interpretation:
                  "Higher step counts are ${_corrStepsCalories!.abs() > 0.5 ? "strongly" : "weakly"} "
                  "associated with caloric expenditure.",
              color: Colors.orange,
            ),
          if (_corrStepsCalories != null && _corrHrBp != null)
            const Divider(height: 20),
          if (_corrHrBp != null)
            _corrRow(
              label: "Wearable HR -> Clinical Systolic BP",
              r: _corrHrBp!,
              interpretation:
                  "Wearable heart rate shows a ${_corrStrength(_corrHrBp!)} relationship "
                  "with clinical blood pressure readings.",
              color: Colors.red,
            ),
        ],
      ),
    );
  }

  String _corrStrength(double r) {
    final abs = r.abs();
    if (abs >= 0.7) return "strong";
    if (abs >= 0.4) return "moderate";
    return "weak";
  }

  Color _corrColor(double r) {
    final abs = r.abs();
    if (abs >= 0.7) return Colors.green;
    if (abs >= 0.4) return Colors.orange;
    return Colors.grey;
  }

  Widget _corrRow({
    required String label,
    required double r,
    required String interpretation,
    required Color color,
  }) {
    final strength = _corrStrength(r);
    final strengthColor = _corrColor(r);
    final direction = r >= 0 ? "positive" : "negative";

    return InsightCorrelationRow(
      label: label,
      value: r,
      badgeLabel: "${strength.toUpperCase()} $direction",
      interpretation: interpretation,
      color: color,
      strengthColor: strengthColor,
    );
  }

  // NEW SECTION: Rule-Based Anomaly Detection Table

  Widget _buildAnomalyRulesSection() {
    return _sectionCard(
      title: "Rule-Based Anomaly Detection",
      subtitle: "Clinical vitals checked against medical thresholds",
      icon: Icons.rule_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Threshold reference
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _thresholdChip("HR: 40-40 bpm", Colors.red),
              _thresholdChip("BP: < 140/90", Colors.blue),
              _thresholdChip("Temp: >=38.0 deg C", Colors.orange),
            ],
          ),
          const SizedBox(height: 14),

          if (_anomalyAlerts.isEmpty)
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  "No threshold violations found in clinical records",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else ...[
            Text(
              "${_anomalyAlerts.length} violation(s) detected:",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            ..._anomalyAlerts.map((a) {
              final isCritical = a["critical"] as bool;
              final color = isCritical ? Colors.red : Colors.orange;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCritical
                          ? Icons.error_outline
                          : Icons.warning_amber_outlined,
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a["metric"] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Value: ${a["value"]}  |  Threshold: ${a["threshold"]}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      a["date"] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _thresholdChip(String label, Color color) {
    return InsightThresholdChip(label: label, color: color);
  }

  // NEW SECTION: Multi-Patient Comparison

  Widget _buildMultiPatientSection() {
    if (_allPatientsStats.isEmpty) return const SizedBox.shrink();

    final maxSteps = _allPatientsStats
        .map((p) => (p["avg_steps"] as double))
        .reduce((a, b) => a > b ? a : b);

    return _sectionCard(
      title: "Multi-Patient Comparison",
      subtitle:
          "Average wearable metrics across ${_allPatientsStats.length} patients",
      icon: Icons.people_outline,
      child: Column(
        children: _allPatientsStats.map((p) {
          final isCurrent = p["is_current"] as bool;
          final pid = p["patient_id"] as String;
          final avgSteps = (p["avg_steps"] as double);
          final avgHR = (p["avg_hr"] as double);
          final avgCal = (p["avg_cal"] as double);
          final progress = maxSteps > 0 ? avgSteps / maxSteps : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.primary.withValues(alpha: 0.06)
                  : Colors.grey.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: isCurrent
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.primary
                            : Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "P$pid",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Patient $pid${isCurrent ? " (You)" : ""}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isCurrent
                            ? AppColors.primary
                            : AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "HR ${avgHR.toStringAsFixed(0)} | ${avgCal.toStringAsFixed(0)} kcal",
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const SizedBox(width: 36),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          backgroundColor: Colors.grey.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCurrent
                                ? AppColors.primary
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${avgSteps.toStringAsFixed(0)} steps",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isCurrent
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // EXISTING: Clinical Summary Section

  Widget _buildClinicalSummarySection() {
    Map<String, dynamic>? latestVH;
    if (_vitalsHistoryData.isNotEmpty) {
      final sorted = List<dynamic>.from(_vitalsHistoryData)
        ..sort(
          (a, b) => (b["recorded_on"] ?? "").toString().compareTo(
            (a["recorded_on"] ?? "").toString(),
          ),
        );
      latestVH = Map<String, dynamic>.from(sorted.first);
    }

    Map<String, dynamic>? latestWearable;
    if (_wearableVitals.isNotEmpty) {
      final sorted = List<dynamic>.from(_wearableVitals)
        ..sort(
          (a, b) => (b["timestamp"] ?? "").toString().compareTo(
            (a["timestamp"] ?? "").toString(),
          ),
        );
      latestWearable = Map<String, dynamic>.from(sorted.first);
    }

    Map<String, dynamic>? latestDiab;
    if (_diabetesData.isNotEmpty)
      latestDiab = Map<String, dynamic>.from(_diabetesData.last);

    Map<String, dynamic>? latestHD;
    if (_heartDiseaseData.isNotEmpty) {
      final sorted = List<dynamic>.from(_heartDiseaseData)
        ..sort(
          (a, b) => (b["analyzed_on"] ?? "").toString().compareTo(
            (a["analyzed_on"] ?? "").toString(),
          ),
        );
      latestHD = Map<String, dynamic>.from(sorted.first);
    }

    Map<String, dynamic>? latestECG;
    if (_ecgData.isNotEmpty) {
      final sorted = List<dynamic>.from(_ecgData)
        ..sort(
          (a, b) => (b["recorded_on"] ?? "").toString().compareTo(
            (a["recorded_on"] ?? "").toString(),
          ),
        );
      latestECG = Map<String, dynamic>.from(sorted.first);
    }

    Map<String, dynamic>? highestStroke;
    if (_strokeData.isNotEmpty) {
      final sorted = List<dynamic>.from(_strokeData)
        ..sort(
          (a, b) =>
              _toDouble(b["risk_score"]).compareTo(_toDouble(a["risk_score"])),
        );
      highestStroke = Map<String, dynamic>.from(sorted.first);
    }

    Map<String, dynamic>? latestDx;
    final realDx = _diagnosisData.where((e) {
      final code = e["diagnosis_code"]?.toString() ?? "";
      return !code.startsWith("DX0") && code.isNotEmpty;
    }).toList();
    if (realDx.isNotEmpty) {
      realDx.sort(
        (a, b) => (b["diagnosis_date"] ?? "").toString().compareTo(
          (a["diagnosis_date"] ?? "").toString(),
        ),
      );
      latestDx = Map<String, dynamic>.from(realDx.first);
    }

    final completedLabs = _labTestsData
        .where((e) => e["status"]?.toString().toLowerCase() == "completed")
        .toList();
    final abnormalLabs = _labTestsData.where((e) {
      final r = e["result"]?.toString().toLowerCase() ?? "";
      return r == "abnormal" || r == "positive";
    }).toList();

    if (latestVH == null &&
        latestDiab == null &&
        latestHD == null &&
        latestECG == null) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.summarize_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.clinicalSummaryTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (latestVH != null) ...[
              _summarySection(
                l10n.clinicalVitalsMostRecent,
                Icons.monitor_heart_outlined,
                AppColors.primary,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(
                    "HR",
                    "${latestVH["heart_rate"] ?? "-"} bpm",
                    Colors.red,
                  ),
                  _chip(
                    "BP",
                    latestVH["blood_pressure"]?.toString() ?? "-",
                    Colors.blue,
                  ),
                  _chip(
                    "Temp",
                    "${latestVH["temperature"] ?? "-"} deg C",
                    Colors.orange,
                  ),
                  _chip(
                    "Resp Rate",
                    "${latestVH["respiratory_rate"] ?? "-"} /min",
                    Colors.teal,
                  ),
                ],
              ),
              if ((latestVH["notes"] ?? "").toString().isNotEmpty &&
                  !(latestVH["notes"].toString().contains("Mock")) &&
                  !(latestVH["notes"].toString().contains("Determine")))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.noteLabel(latestVH["notes"].toString()),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              const SizedBox(height: 12),
            ],

            if (latestWearable != null) ...[
              _summarySection(
                l10n.wearableActivityMostRecent,
                Icons.watch_outlined,
                AppColors.primary,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(
                    "Steps",
                    latestWearable["steps"]?.toString() ?? "-",
                    AppColors.primary,
                  ),
                  _chip(
                    "Calories",
                    latestWearable["calories"]?.toString() ?? "-",
                    Colors.deepOrange,
                  ),
                  _chip(
                    "Sleep",
                    "${latestWearable["sleep"] ?? "-"} hrs",
                    Colors.teal,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            if (latestDiab != null) ...[
              _summarySection(
                "Glucose Wellness Indicators",
                Icons.bloodtype_outlined,
                Colors.red,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(
                    "Glucose",
                    "${_toDouble(latestDiab["glucose_level"]).toStringAsFixed(1)} mg/dL",
                    _toDouble(latestDiab["glucose_level"]) > 126
                        ? Colors.red
                        : Colors.green,
                  ),
                  _chip(
                    "Insulin",
                    "${_toDouble(latestDiab["insulin"]).toStringAsFixed(2)} uU/mL",
                    Colors.blueGrey,
                  ),
                  _chip(
                    "Prediction",
                    latestDiab["prediction"]?.toString() ?? "-",
                    (latestDiab["prediction"]?.toString().toLowerCase() ==
                            "positive")
                        ? Colors.red
                        : Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            if (latestHD != null) ...[
              _summarySection(
                "Heart Health Indicators",
                Icons.favorite_outline,
                Colors.pink,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(
                    "Cholesterol",
                    "${_toDouble(latestHD["cholesterol"]).toStringAsFixed(1)} mg/dL",
                    _toDouble(latestHD["cholesterol"]) > 200
                        ? Colors.orange
                        : Colors.green,
                  ),
                  _chip(
                    "Resting BP",
                    "${_toDouble(latestHD["resting_bp"]).toStringAsFixed(0)} mmHg",
                    Colors.blue,
                  ),
                  _chip("Age", "${latestHD["age"] ?? "-"}", Colors.blueGrey),
                  _chip(
                    "Risk Score",
                    "${(_toDouble(latestHD["risk_score"]) * 100).toStringAsFixed(0)}%",
                    _toDouble(latestHD["risk_score"]) > 0.7
                        ? Colors.red
                        : _toDouble(latestHD["risk_score"]) > 0.4
                        ? Colors.orange
                        : Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            if (latestECG != null) ...[
              _summarySection("ECG Result", Icons.show_chart, Colors.teal),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(
                    "Result",
                    latestECG["ecg_result"]?.toString() ?? "-",
                    latestECG["ecg_result"]?.toString().toLowerCase() ==
                            "abnormal"
                        ? Colors.red
                        : latestECG["ecg_result"]?.toString().toLowerCase() ==
                              "borderline"
                        ? Colors.orange
                        : Colors.green,
                  ),
                  _chip(
                    "Recorded",
                    _formatShortDate(
                      latestECG["recorded_on"]?.toString() ?? "",
                    ),
                    Colors.blueGrey,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            if (highestStroke != null) ...[
              _summarySection(
                "Stroke Risk Indicators (Highest)",
                Icons.warning_amber_outlined,
                Colors.deepOrange,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(
                    "Risk Score",
                    "${(_toDouble(highestStroke["risk_score"]) * 100).toStringAsFixed(0)}%",
                    _toDouble(highestStroke["risk_score"]) >= 0.7
                        ? Colors.red
                        : _toDouble(highestStroke["risk_score"]) >= 0.4
                        ? Colors.orange
                        : Colors.green,
                  ),
                  _chip(
                    "Model",
                    highestStroke["model_version"]?.toString() ?? "-",
                    Colors.blueGrey,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            if (_labTestsData.isNotEmpty) ...[
              _summarySection(
                "Lab Tests",
                Icons.biotech_outlined,
                Colors.brown,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip("Total", "${_labTestsData.length}", Colors.blueGrey),
                  _chip("Completed", "${completedLabs.length}", Colors.green),
                  _chip(
                    "Abnormal",
                    "${abnormalLabs.length}",
                    abnormalLabs.isNotEmpty ? Colors.red : Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            if (latestDx != null) ...[
              _summarySection(
                "Latest Clinical Record (ICD-10)",
                Icons.medical_services_outlined,
                AppColors.primary,
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            latestDx["diagnosis_code"]?.toString() ?? "-",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatShortDate(
                            latestDx["diagnosis_date"]?.toString() ?? "",
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      latestDx["diagnosis_description"]?.toString() ?? "-",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // DISCLAIMER BANNER

  Widget _buildDisclaimerBanner() {
    return InsightDisclaimerBanner(text: context.l10n.insightsDisclaimer);
  }

  // SHARED WIDGET HELPERS

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return InsightSectionCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      child: child,
    );
  }

  Widget _legendDot(Color color, String label) {
    return InsightLegendDot(color: color, label: label);
  }

  Widget _summarySection(String label, IconData icon, Color color) {
    return InsightSummarySection(label: label, icon: icon, color: color);
  }

  Widget _chip(String label, String value, Color color) {
    return InsightChip(label: label, value: value, color: color);
  }

  String _formatShortDate(String raw) {
    try {
      return DateFormat("MMM dd, yyyy").format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  Color _severityColor(String s) {
    switch (s) {
      case "critical":
        return const Color(0xFFD32F2F);
      case "warning":
        return const Color(0xFFF57C00);
      default:
        return const Color(0xFF388E3C);
    }
  }

  Color _severityBgColor(String s) {
    switch (s) {
      case "critical":
        return const Color(0xFFFFEBEE);
      case "warning":
        return const Color(0xFFFFF3E0);
      default:
        return const Color(0xFFE8F5E9);
    }
  }

  IconData _severityIcon(String s) {
    switch (s) {
      case "critical":
        return Icons.error_outline;
      case "warning":
        return Icons.warning_amber_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  String _severityLabel(String s) {
    switch (s) {
      case "critical":
        return "CRITICAL";
      case "warning":
        return "WARNING";
      default:
        return "NORMAL";
    }
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    final severity = insight["severity"] as String;
    final color = _severityColor(severity);
    final bgColor = _severityBgColor(severity);

    return HealthInsightCard(
      insight: insight,
      color: color,
      backgroundColor: bgColor,
      icon: _severityIcon(severity),
      severityLabel: _severityLabel(severity),
    );
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.healthInsightsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refreshTooltip,
            onPressed: () {
              setState(() => _loading = true);
              _loadInsights();
            },
          ),
        ],
      ),
      body: _loading
          ? const LoadingStateView()
          : RefreshIndicator(
              onRefresh: () async {
                setState(() => _loading = true);
                await _loadInsights();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: InsightsStyles.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDisclaimerBanner(),
                    InsightsAnalysisHeader(
                      title: l10n.unifiedHealthAnalysisTitle,
                      subtitle: l10n.unifiedHealthAnalysisSubtitle,
                      mergedPairsLabel: _mergedRecords.isEmpty
                          ? null
                          : l10n.mergedRecordPairs(_mergedRecords.length),
                    ),

                    const SizedBox(height: 16),

                    // Wellness disclaimer
                    _buildDisclaimerBanner(),

                    // Insight cards
                    InsightsCountHeader(
                      label: l10n.insightsFound(_insights.length),
                    ),
                    const SizedBox(height: 14),
                    ..._insights.map(_buildInsightCard),

                    // NEW: Wearable vs Clinical HR Comparison
                    _buildComparisonChartSection(),

                    // NEW: Pearson Correlation
                    _buildCorrelationSection(),

                    // NEW: Rule-Based Anomaly Table
                    _buildAnomalyRulesSection(),

                    // Clinical Summary
                    _buildClinicalSummarySection(),

                    // NEW: Multi-Patient Comparison
                    _buildMultiPatientSection(),

                    const SizedBox(height: 8),
                    InsightsMedicalFooter(text: l10n.insightsMedicalFooter),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}

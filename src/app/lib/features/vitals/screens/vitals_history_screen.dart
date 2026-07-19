import '../../../services/e_hospital_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../ui/ui.dart';
import '../presentation/vitals_history_styles.dart';
import '../widgets/vitals_history_data_card.dart';
import '../widgets/vitals_history_disclaimer.dart';
import '../widgets/vitals_history_related_tiles.dart';
import '../widgets/vitals_history_summary_banner.dart';
import '../widgets/vitals_history_tab_bar.dart';
import '../widgets/vitals_related_records_header.dart';

class VitalsHistoryScreen extends StatefulWidget {
  const VitalsHistoryScreen({Key? key}) : super(key: key);

  @override
  State<VitalsHistoryScreen> createState() => _VitalsHistoryScreenState();
}

class _VitalsHistoryScreenState extends State<VitalsHistoryScreen> {
  bool loading = true;
  List<dynamic> vitals = [];

  // Chart data is ordered oldest -> newest for a left-to-right trend.
  List<FlSpot> heartRateSpots = [];
  List<FlSpot> temperatureSpots = [];
  List<FlSpot> respiratorySpots = [];
  List<FlSpot> systolicSpots = [];
  List<FlSpot> diastolicSpots = [];
  List<String> timeLabels = [];
  List<int> _bottomTitleIndices = [];
  int selectedIndex = 0;

  List<dynamic> labTests = [];
  List<dynamic> diabetes = [];
  List<dynamic> heartDisease = [];
  List<dynamic> ecgList = [];
  List<dynamic> strokeData = [];
  List<dynamic> diagnosisList = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawId = prefs.get("patient_id");
    final patientId = int.tryParse(rawId?.toString() ?? '');

    if (patientId == null) {
      if (mounted) setState(() => loading = false);
      return;
    }

    debugPrint("[VitalsHistory] Loading history for patient_id=$patientId");

    try {
      final filtered = await EHospitalService.fetchTable(
        'vitals_history',
        patientId: patientId.toString(),
      );

      final tsKey = (dynamic item) =>
          item["timestamp"] ?? item["recorded_on"] ?? "";
      filtered.sort(
        (a, b) => DateTime.parse(tsKey(a)).compareTo(DateTime.parse(tsKey(b))),
      );

      _buildChartData(filtered);

      final results = await Future.wait([
        _fetchTableForPatient("lab_tests", patientId),
        _fetchTableForPatient("diabetes_analysis", patientId),
        _fetchTableForPatient("heart_disease_analysis", patientId),
        _fetchTableForPatient("ecg", patientId),
        _fetchTableForPatient("stroke_prediction", patientId),
        _fetchTableForPatient("diagnosis", patientId),
      ]);

      if (mounted) {
        setState(() {
          vitals = filtered;
          labTests = results[0];
          diabetes = results[1];
          heartDisease = results[2];
          ecgList = results[3];
          strokeData = results[4];
          diagnosisList = results[5];
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
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

  void _buildChartData(List<dynamic> sortedVitals) {
    heartRateSpots = [];
    temperatureSpots = [];
    respiratorySpots = [];
    systolicSpots = [];
    diastolicSpots = [];
    timeLabels = [];

    for (int i = 0; i < sortedVitals.length; i++) {
      final v = sortedVitals[i];
      final ts = v["timestamp"] ?? v["recorded_on"] ?? "";
      timeLabels.add(_formatAxisDate(ts.toString()));

      final hr = _toDouble(v["heart_rate"]);
      final temp = _toDouble(v["temperature"]);
      final resp = _toDouble(v["respiratory_rate"]);
      final bp = _parseBloodPressure(v["blood_pressure"]);

      heartRateSpots.add(FlSpot(i.toDouble(), hr));
      temperatureSpots.add(FlSpot(i.toDouble(), temp));
      respiratorySpots.add(FlSpot(i.toDouble(), resp));
      systolicSpots.add(FlSpot(i.toDouble(), bp.$1));
      diastolicSpots.add(FlSpot(i.toDouble(), bp.$2));
    }
    _buildBottomTitleIndices();
  }

  void _buildBottomTitleIndices() {
    final n = timeLabels.length;
    if (n == 0) {
      _bottomTitleIndices = [];
      return;
    }
    final step = n <= 5 ? 1 : (n / 5).ceil();
    final candidates = <int>{0};
    for (int i = step; i < n - 1; i += step) candidates.add(i);
    if (n > 1) candidates.add(n - 1);
    final seen = <String>{};
    _bottomTitleIndices = [];
    for (final i in candidates.toList()..sort()) {
      final t = timeLabels[i];
      if (seen.contains(t)) continue;
      seen.add(t);
      _bottomTitleIndices.add(i);
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  (double, double) _parseBloodPressure(dynamic value) {
    if (value == null) return (0.0, 0.0);
    final s = value.toString().trim().split("/");
    if (s.length < 2) return (0.0, 0.0);
    final sys = double.tryParse(s[0].trim()) ?? 0.0;
    final dia = double.tryParse(s[1].trim()) ?? 0.0;
    return (sys, dia);
  }

  String _formatAxisDate(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return DateFormat("MM/dd HH:mm").format(dt);
    } catch (_) {
      return "";
    }
  }

  static const _historyTabs = [
    VitalsHistoryTabItem(
      icon: Icons.favorite_border,
      label: "Heart Rate",
      color: Colors.red,
    ),
    VitalsHistoryTabItem(
      icon: Icons.thermostat,
      label: "Temperature",
      color: Colors.orange,
    ),
    VitalsHistoryTabItem(
      icon: Icons.air,
      label: "Respiratory",
      color: Colors.teal,
    ),
    VitalsHistoryTabItem(
      icon: Icons.monitor_heart,
      label: "Blood Pressure",
      color: Colors.blue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vitalsHistoryTitle)),
      body: loading
          ? const LoadingStateView()
          : SingleChildScrollView(
              padding: VitalsHistoryStyles.bodyPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VitalsHistoryDisclaimer(text: l10n.historyDisclaimer),
                  VitalsHistorySummaryBanner(
                    title: l10n.clinicalVitalsHistoryTitle,
                    subtitle: l10n.recordsFound(vitals.length),
                  ),
                  const SizedBox(height: 24),

                  if (vitals.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: VitalsHistoryStyles.emptyDecoration,
                      child: Center(
                        child: Text(
                          l10n.noVitalsHistoryFound,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    VitalsHistoryTabBar(
                      tabs: _historyTabs,
                      selectedIndex: selectedIndex,
                      onSelected: (index) =>
                          setState(() => selectedIndex = index),
                    ),
                    const SizedBox(height: 16),
                    _buildChartSection(),
                  ],

                  const SizedBox(height: 28),

                  VitalsRelatedRecordsHeader(title: l10n.relatedRecordsTitle),
                  const SizedBox(height: 14),
                  VitalsHistoryDisclaimer(text: l10n.historyDisclaimer),
                  _buildDataCard(
                    l10n.labTestsTitle,
                    labTests,
                    Icons.biotech,
                    _buildLabTestTile,
                  ),
                  _buildDataCard(
                    l10n.ecgTitle,
                    ecgList,
                    Icons.monitor_heart,
                    _buildEcgTile,
                  ),
                  _buildDataCard(
                    l10n.glucoseWellnessTitle,
                    diabetes,
                    Icons.bloodtype,
                    _buildDiabetesTile,
                  ),
                  _buildDataCard(
                    l10n.heartHealthIndicatorsTitle,
                    heartDisease,
                    Icons.favorite,
                    _buildHeartDiseaseTile,
                  ),
                  _buildDataCard(
                    l10n.strokeRiskIndicatorsTitle,
                    strokeData,
                    Icons.warning_amber_outlined,
                    _buildStrokePredictionTile,
                  ),
                  _buildDataCard(
                    l10n.clinicalRecordsTitle,
                    diagnosisList,
                    Icons.medical_services_outlined,
                    _buildDiagnosisTile,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildDataCard(
    String title,
    List<dynamic> items,
    IconData icon,
    Widget Function(dynamic) tileBuilder,
  ) {
    final l10n = context.l10n;
    return VitalsHistoryDataCard(
      title: title,
      items: items,
      icon: icon,
      emptyLabel: l10n.noDataAvailable,
      moreLabelBuilder: l10n.moreRecords,
      tileBuilder: tileBuilder,
    );
  }

  Widget _buildLabTestTile(dynamic e) {
    final type = e["test_type"]?.toString() ?? "-";
    final status = e["status"]?.toString() ?? "-";
    final result = e["result"]?.toString() ?? "-";
    final location = e["lab_location"]?.toString() ?? "-";
    final sampleType = e["sample_type"]?.toString() ?? "-";
    final raw = e["test_date"]?.toString() ?? "";
    String dateStr = raw;
    try {
      dateStr = DateFormat("MMM dd, yyyy").format(DateTime.parse(raw));
    } catch (_) {}

    // Color-code result
    Color resultColor = Colors.green;
    if (result.toLowerCase() == "abnormal" ||
        result.toLowerCase() == "positive") {
      resultColor = Colors.red;
    } else if (result.toLowerCase() == "pending" ||
        status.toLowerCase() == "processing") {
      resultColor = Colors.orange;
    }

    return VitalsHistoryLabTestTile(
      type: type,
      result: result,
      resultColor: resultColor,
      statusLine: "Status: $status  |  Sample: $sampleType",
      locationLine: "Location: $location  |  $dateStr",
    );
  }

  Widget _buildEcgTile(dynamic e) {
    final result = e["ecg_result"]?.toString() ?? "-";
    final on = e["recorded_on"]?.toString() ?? "-";
    String dateStr = on;
    try {
      dateStr = DateFormat("MMM dd, yyyy").format(DateTime.parse(on));
    } catch (_) {}
    return VitalsHistoryTextTile(
      primary: "Result: $result",
      secondary: dateStr,
    );
  }

  Widget _buildDiabetesTile(dynamic e) {
    final glucose = e["glucose_level"]?.toString() ?? "-";
    final insulin = e["insulin"]?.toString() ?? "-";
    final prediction = e["prediction"]?.toString() ?? "-";
    return VitalsHistoryTextTile(
      primary: "Prediction: $prediction",
      secondary: "Glucose: $glucose | Insulin: $insulin",
    );
  }

  Widget _buildHeartDiseaseTile(dynamic e) {
    final prediction = e["prediction"]?.toString() ?? "-";
    final risk = e["risk_score"]?.toString() ?? "-";
    final cholesterol = e["cholesterol"]?.toString() ?? "-";
    final bp = e["resting_bp"]?.toString() ?? "-";
    final date = e["analyzed_on"]?.toString() ?? "-";
    return VitalsHistoryTextTile(
      primary: "Prediction: $prediction | Risk: $risk",
      secondary: "Cholesterol: $cholesterol | BP: $bp | $date",
    );
  }

  Widget _buildStrokePredictionTile(dynamic e) {
    final riskScore = _toDouble(e["risk_score"]);
    final modelVersion = e["model_version"]?.toString() ?? "-";
    final raw = e["predicted_on"]?.toString() ?? "";
    String dateStr = raw;
    try {
      dateStr = DateFormat("MMM dd, yyyy").format(DateTime.parse(raw));
    } catch (_) {}

    // Classify risk level from score
    String riskLabel;
    Color riskColor;
    if (riskScore >= 0.7) {
      riskLabel = "High Risk";
      riskColor = Colors.red;
    } else if (riskScore >= 0.4) {
      riskLabel = "Moderate Risk";
      riskColor = Colors.orange;
    } else {
      riskLabel = "Low Risk";
      riskColor = Colors.green;
    }

    return VitalsHistoryRiskTile(
      primary: "Risk Score: ${(riskScore * 100).toStringAsFixed(0)}%",
      badge: riskLabel,
      badgeColor: riskColor,
      secondary: "Model: $modelVersion | $dateStr",
    );
  }

  Widget _buildDiagnosisTile(dynamic e) {
    final code = e["diagnosis_code"]?.toString() ?? "-";
    final description = e["diagnosis_description"]?.toString() ?? "-";
    final raw = e["diagnosis_date"]?.toString() ?? "";
    String dateStr = raw;
    try {
      dateStr = DateFormat("MMM dd, yyyy").format(DateTime.parse(raw));
    } catch (_) {}

    return VitalsHistoryDiagnosisTile(
      code: code,
      date: dateStr,
      description: description,
    );
  }

  Widget _buildChartSection() {
    final titles = [
      "Heart Rate",
      "Temperature",
      "Respiratory Rate",
      "Blood Pressure",
    ];
    final title = titles[selectedIndex];
    double maxY;
    List<LineChartBarData> lineBars;
    if (selectedIndex == 0) {
      maxY =
          (heartRateSpots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b) +
                  20)
              .clamp(60.0, 200.0);
      lineBars = [
        LineChartBarData(
          spots: heartRateSpots,
          isCurved: true,
          color: Colors.red,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.red.withValues(alpha: 0.1),
          ),
        ),
      ];
    } else if (selectedIndex == 1) {
      maxY =
          (temperatureSpots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b) +
                  1)
              .clamp(35.0, 42.0);
      lineBars = [
        LineChartBarData(
          spots: temperatureSpots,
          isCurved: true,
          color: Colors.orange,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.orange.withValues(alpha: 0.1),
          ),
        ),
      ];
    } else if (selectedIndex == 2) {
      maxY =
          (respiratorySpots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b) +
                  5)
              .clamp(10.0, 40.0);
      lineBars = [
        LineChartBarData(
          spots: respiratorySpots,
          isCurved: true,
          color: Colors.teal,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.teal.withValues(alpha: 0.1),
          ),
        ),
      ];
    } else {
      final allSys = systolicSpots.map((s) => s.y);
      final allDia = diastolicSpots.map((s) => s.y);
      final maxVal = [...allSys, ...allDia].fold(0.0, (a, b) => a > b ? a : b);
      maxY = (maxVal + 20).clamp(80.0, 200.0);
      lineBars = [
        LineChartBarData(
          spots: systolicSpots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
        LineChartBarData(
          spots: diastolicSpots,
          isCurved: true,
          color: Colors.purple,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$title - Trend",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (selectedIndex == 3)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: Colors.blue),
                const SizedBox(width: 6),
                const Text(
                  "Systolic",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(width: 16),
                Icon(Icons.circle, size: 10, color: Colors.purple),
                const SizedBox(width: 6),
                const Text(
                  "Diastolic",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: LineChart(
            LineChartData(
              maxY: maxY,
              minY: selectedIndex == 1 ? 35.0 : 0,
              lineBarsData: lineBars,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 ||
                          i >= timeLabels.length ||
                          !_bottomTitleIndices.contains(i)) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          timeLabels[i],
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    },
                    reservedSize: 24,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 36),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
            ),
          ),
        ),
      ],
    );
  }
}

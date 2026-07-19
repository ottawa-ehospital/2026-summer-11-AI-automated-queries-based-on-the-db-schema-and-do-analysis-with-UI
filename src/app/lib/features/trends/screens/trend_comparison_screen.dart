import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../services/backend_api_service.dart';
import '../../../services/e_hospital_service.dart';
import '../../../ui/ui.dart';
import '../presentation/trend_styles.dart';
import '../widgets/trend_disclaimer_banner.dart';
import '../widgets/trend_legend_dot.dart';
import '../widgets/trend_metric_card.dart';

class TrendComparisonScreen extends StatefulWidget {
  const TrendComparisonScreen({super.key});

  @override
  State<TrendComparisonScreen> createState() => _TrendComparisonScreenState();
}

class _TrendComparisonScreenState extends State<TrendComparisonScreen> {
  bool _loading = true;
  String? _errorMsg;

  double _thisWeekSteps = 0;
  double _lastWeekSteps = 0;
  double _thisWeekCalories = 0;
  double _lastWeekCalories = 0;
  double _thisWeekSleep = 0;
  double _lastWeekSleep = 0;
  double _thisWeekHR = 0;
  double _lastWeekHR = 0;
  String currentPatientId = '';

  final Map<String, String?> _aiInsights = {};
  bool _aiGenerating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawId = prefs.get('patient_id');
    if (rawId == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = context.l10n.profileNotLoggedIn;
        });
      }
      return;
    }

    final patientId = int.tryParse(rawId.toString());
    if (patientId == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = context.l10n.profileInvalidPatientId;
        });
      }
      return;
    }

    try {
      final records = await EHospitalService.fetchTable(
        'wearable_vitals',
        patientId: patientId.toString(),
      );

      final anchor = _latestRecordTimestamp(records) ?? DateTime.now();
      final thisMonday = DateTime(
        anchor.year,
        anchor.month,
        anchor.day,
      ).subtract(Duration(days: anchor.weekday - 1));
      final lastMonday = thisMonday.subtract(const Duration(days: 7));
      final lastSunday = thisMonday.subtract(const Duration(days: 1));

      final thisWeek = <Map<String, dynamic>>[];
      final lastWeek = <Map<String, dynamic>>[];

      for (final record in records) {
        final dateStr =
            record['date'] as String? ?? record['timestamp'] as String? ?? '';
        if (dateStr.isEmpty) continue;
        try {
          final dt = DateTime.parse(dateStr);
          if (!dt.isBefore(thisMonday)) {
            thisWeek.add(Map<String, dynamic>.from(record));
          } else if (!dt.isBefore(lastMonday) && !dt.isAfter(lastSunday)) {
            lastWeek.add(Map<String, dynamic>.from(record));
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _thisWeekSteps = _avg(thisWeek, 'steps');
          _lastWeekSteps = _avg(lastWeek, 'steps');
          _thisWeekCalories = _avg(thisWeek, 'calories');
          _lastWeekCalories = _avg(lastWeek, 'calories');
          _thisWeekSleep = _avg(thisWeek, 'sleep');
          _lastWeekSleep = _avg(lastWeek, 'sleep');
          _thisWeekHR = _avg(thisWeek, 'heart_rate');
          _lastWeekHR = _avg(lastWeek, 'heart_rate');
          currentPatientId = patientId.toString();
          _loading = false;
        });
        _generateInsights();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = context.l10n.assistantErrorMessage(error.toString());
        });
      }
    }
  }

  double _avg(List<Map<String, dynamic>> list, String key) {
    if (list.isEmpty) return 0;
    final values = list
        .map((entry) => double.tryParse((entry[key] ?? '0').toString()) ?? 0.0)
        .where((value) => value > 0)
        .toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  DateTime? _latestRecordTimestamp(List<dynamic> records) {
    DateTime? latest;
    for (final record in records) {
      if (record is! Map) continue;
      final value =
          record['date']?.toString() ?? record['timestamp']?.toString() ?? '';
      if (value.isEmpty) continue;
      try {
        final timestamp = DateTime.parse(value);
        if (latest == null || timestamp.isAfter(latest)) latest = timestamp;
      } catch (_) {}
    }
    return latest;
  }

  Future<void> _generateInsights() async {
    if (mounted) {
      setState(() {
        _aiGenerating = true;
        _aiInsights.clear();
      });
    }

    try {
      final insights = await BackendApiService.trendInsights(
        patientId: currentPatientId,
        steps: {'last_week': _lastWeekSteps, 'this_week': _thisWeekSteps},
        calories: {
          'last_week': _lastWeekCalories,
          'this_week': _thisWeekCalories,
        },
        heartRate: {'last_week': _lastWeekHR, 'this_week': _thisWeekHR},
        sleep: {'last_week': _lastWeekSleep, 'this_week': _thisWeekSleep},
      );
      _aiInsights.addAll(insights);
    } catch (_) {}

    if (mounted) setState(() => _aiGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverHeader(
            title: l10n.trendAnalysisTitle,
            icon: Icons.trending_up,
          ),
          if (_loading)
            SliverStateView.loading()
          else if (_errorMsg != null)
            SliverStateView.error(message: _errorMsg!)
          else
            SliverPadding(
              padding: TrendStyles.bodyPadding,
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  TrendDisclaimerBanner(text: l10n.trendDisclaimer),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TrendLegendDot(
                        color: Colors.blue.shade300,
                        label: l10n.lastWeekLabel,
                      ),
                      const SizedBox(width: 20),
                      TrendLegendDot(
                        color: AppColors.primary,
                        label: l10n.thisWeekLabel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TrendMetricCard(
                    l10n: l10n,
                    icon: Icons.directions_walk,
                    title: l10n.stepsTitle,
                    description: l10n.stepsTrendDescription,
                    thisWeek: _thisWeekSteps,
                    lastWeek: _lastWeekSteps,
                    unit: l10n.stepsUnit,
                    color: Colors.blue,
                    normalMin: 5000,
                    normalMax: 15000,
                    aiText: _aiInsights[l10n.stepsTitle],
                    aiGenerating: _aiGenerating,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TrendMetricCard(
                    l10n: l10n,
                    icon: Icons.local_fire_department_outlined,
                    title: l10n.activeCaloriesTitle,
                    description: l10n.activeCaloriesTrendDescription,
                    thisWeek: _thisWeekCalories,
                    lastWeek: _lastWeekCalories,
                    unit: l10n.kcalUnit,
                    color: Colors.orange,
                    normalMin: 300,
                    normalMax: 600,
                    aiText: _aiInsights[l10n.activeCaloriesTitle],
                    aiGenerating: _aiGenerating,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TrendMetricCard(
                    l10n: l10n,
                    icon: Icons.favorite_border,
                    title: l10n.heartRateTitle,
                    description: l10n.heartRateTrendDescription,
                    thisWeek: _thisWeekHR,
                    lastWeek: _lastWeekHR,
                    unit: l10n.bpmUnit,
                    color: Colors.red,
                    normalMin: 60,
                    normalMax: 100,
                    aiText: _aiInsights[l10n.heartRateTitle],
                    aiGenerating: _aiGenerating,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TrendMetricCard(
                    l10n: l10n,
                    icon: Icons.bedtime_outlined,
                    title: l10n.sleepTitle,
                    description: l10n.sleepTrendDescription,
                    thisWeek: _thisWeekSleep,
                    lastWeek: _lastWeekSleep,
                    unit: l10n.hrsUnit,
                    color: AppColors.primary,
                    normalMin: 7,
                    normalMax: 9,
                    aiText: _aiInsights[l10n.sleepTitle],
                    aiGenerating: _aiGenerating,
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

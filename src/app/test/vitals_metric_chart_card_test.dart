import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_health_app/features/vitals/widgets/vitals_metric_chart_card.dart';
import 'package:smart_health_app/features/vitals/widgets/vitals_metric_tab_row.dart';

void main() {
  testWidgets('VitalsMetricChartCard renders stress metric labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VitalsMetricChartCard(
              tab: const VitalsMetricTabData(
                icon: Icons.psychology,
                label: 'Stress',
                color: Colors.deepPurple,
              ),
              spots: const [FlSpot(0, 46.4), FlSpot(1, 38)],
              timeLabels: const ['10:00', '11:00'],
              selectedIndex: 4,
              unit: 'score',
              maxY: 100,
              normalMin: 0,
              normalMax: 40,
              description:
                  'Derived from HRV, resting heart rate, and respiration.',
              dataNote: 'Tap stress points to add context annotations.',
              liveBaselineHeartRate: 72,
              aiText: 'Stress is slightly elevated.',
              aiGenerating: false,
              aiInsightLabel: 'AI Insight',
              generatingLabel: 'Generating...',
              emptyInsightLabel: 'No insight yet.',
              normalRangeLabel: 'Normal range',
              latestLabel: 'Latest',
              averageLabel: 'Average',
              minLabel: 'Min',
              maxLabel: 'Max',
              noDataLabel: 'No data',
              lowLabel: 'Low',
              highLabel: 'High',
              normalLabel: 'Normal',
              annotatedIndices: const {1},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Stress Trend'), findsOneWidget);
    expect(find.text('Normal range: 0-40 score'), findsOneWidget);
    expect(find.text('Stress is slightly elevated.'), findsOneWidget);
    expect(
      find.text('Tap stress points to add context annotations.'),
      findsOneWidget,
    );
  });
}

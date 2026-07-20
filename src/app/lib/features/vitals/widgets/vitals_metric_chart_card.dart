import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../config/api_config.dart';
import '../../../ui/ui.dart';
import '../presentation/vitals_styles.dart';
import 'vitals_metric_tab_row.dart';

class VitalsMetricChartCard extends StatelessWidget {
  final VitalsMetricTabData tab;
  final List<FlSpot> spots;
  final List<String> timeLabels;
  final int selectedIndex;
  final String unit;
  final double maxY;
  final double normalMin;
  final double normalMax;
  final String description;
  final String dataNote;
  final double liveBaselineHeartRate;
  final String? aiText;
  final bool aiGenerating;
  final String aiInsightLabel;
  final String generatingLabel;
  final String emptyInsightLabel;
  final String normalRangeLabel;
  final String latestLabel;
  final String averageLabel;
  final String minLabel;
  final String maxLabel;
  final String noDataLabel;
  final String lowLabel;
  final String highLabel;
  final String normalLabel;
  final void Function(int index)? onSpotTap;
  final Set<int> annotatedIndices;

  const VitalsMetricChartCard({
    super.key,
    required this.tab,
    required this.spots,
    required this.timeLabels,
    required this.selectedIndex,
    required this.unit,
    required this.maxY,
    required this.normalMin,
    required this.normalMax,
    required this.description,
    required this.dataNote,
    required this.liveBaselineHeartRate,
    required this.aiText,
    required this.aiGenerating,
    required this.aiInsightLabel,
    required this.generatingLabel,
    required this.emptyInsightLabel,
    required this.normalRangeLabel,
    required this.latestLabel,
    required this.averageLabel,
    required this.minLabel,
    required this.maxLabel,
    required this.noDataLabel,
    required this.lowLabel,
    required this.highLabel,
    required this.normalLabel,
    this.onSpotTap,
    this.annotatedIndices = const {},
  });

  @override
  Widget build(BuildContext context) {
    final nonZero = spots.map((s) => s.y).where((v) => v > 0).toList();
    final latest = spots.isNotEmpty ? spots.last.y : 0.0;
    final avg = nonZero.isNotEmpty
        ? nonZero.reduce((a, b) => a + b) / nonZero.length
        : 0.0;
    final minVal = nonZero.isNotEmpty
        ? nonZero.reduce((a, b) => a < b ? a : b)
        : 0.0;
    final maxVal = nonZero.isNotEmpty
        ? nonZero.reduce((a, b) => a > b ? a : b)
        : 0.0;
    final status = _statusFor(latest);
    final lastRecordedLabel = timeLabels.isNotEmpty ? timeLabels.last : '';

    return Container(
      decoration: VitalsStyles.metricCardDecoration,
      padding: VitalsStyles.metricCardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricHeader(
            tab: tab,
            title: '${tab.label} Trend',
            description: description,
            latestValue: latest > 0
                ? '${_formatMetric(latest)} $unit'
                : '- $unit',
            statusLabel: status.label,
            statusColor: status.color,
            lastRecordedLabel: lastRecordedLabel,
          ),
          const SizedBox(height: 6),
          _NormalRangeLegend(
            text:
                '$normalRangeLabel: ${_formatMetric(normalMin)}-${_formatMetric(normalMax)} $unit',
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(height: 260, child: LineChart(_chartData())),
          if (nonZero.isNotEmpty) ...[
            const SizedBox(height: 14),
            _StatsRow(
              color: tab.color,
              cells: [
                _StatData(
                  label: latestLabel,
                  value: latest > 0
                      ? '${_formatMetric(latest)} $unit'
                      : noDataLabel,
                  color: tab.color,
                ),
                _StatData(
                  label: averageLabel,
                  value: '${_formatMetric(avg)} $unit',
                  color: Colors.blueGrey,
                ),
                _StatData(
                  label: minLabel,
                  value: '${_formatMetric(minVal)} $unit',
                  color: Colors.green,
                ),
                _StatData(
                  label: maxLabel,
                  value: '${_formatMetric(maxVal)} $unit',
                  color: Colors.orange,
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          _AiSummary(
            text: aiText,
            loading: aiGenerating && aiText == null,
            statusLabel: status.label,
            statusColor: status.color,
            title: aiInsightLabel,
            generatingLabel: generatingLabel,
            emptyLabel: emptyInsightLabel,
          ),
          if (dataNote.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 13,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 5),
                Expanded(child: Text(dataNote, style: VitalsStyles.metricNote)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  ({String label, Color color}) _statusFor(double latest) {
    if (latest <= 0) return (label: noDataLabel, color: Colors.grey);
    if (latest < normalMin) return (label: lowLabel, color: Colors.orange);
    if (latest > normalMax) return (label: highLabel, color: Colors.red);
    return (label: normalLabel, color: Colors.green);
  }

  LineChartData _chartData() {
    return LineChartData(
      maxY: maxY,
      minY: 0,
      rangeAnnotations: RangeAnnotations(
        horizontalRangeAnnotations: [
          HorizontalRangeAnnotation(
            y1: normalMin,
            y2: normalMax,
            color: Colors.green.withValues(alpha: 0.07),
          ),
        ],
      ),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: normalMin,
            color: Colors.green.withValues(alpha: 0.35),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
          HorizontalLine(
            y: normalMax,
            color: Colors.green.withValues(alpha: 0.35),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ],
      ),
      lineBarsData: [
        if (selectedIndex == 2)
          LineChartBarData(
            spots: [
              FlSpot(0, liveBaselineHeartRate),
              FlSpot(
                timeLabels.isEmpty ? 0 : (timeLabels.length - 1).toDouble(),
                liveBaselineHeartRate,
              ),
            ],
            color: Colors.green.withValues(alpha: 0.5),
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
            barWidth: 2,
          ),
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: tab.color,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          showingIndicators: annotatedIndices.toList(),
          belowBarData: BarAreaData(
            show: true,
            color: tab.color.withValues(alpha: 0.08),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchCallback: (event, response) {
          if (!event.isInterestedForInteractions || onSpotTap == null) return;
          final touched = response?.lineBarSpots;
          if (touched == null || touched.isEmpty) return;
          onSpotTap!(touched.first.spotIndex);
        },
      ),
      titlesData: _titlesData(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: Colors.grey.shade100, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      clipData: const FlClipData.all(),
    );
  }

  FlTitlesData _titlesData() {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i >= 0 &&
                i < timeLabels.length &&
                i % 10 == 0 &&
                i < timeLabels.length - 5) {
              return Transform.rotate(
                angle: -0.5,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(timeLabels[i], style: VitalsStyles.axisLabel),
                ),
              );
            }
            return const SizedBox.shrink();
          },
          reservedSize: 44,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 38,
          getTitlesWidget: (value, _) => Text(
            value.toInt().toString(),
            style: VitalsStyles.axisLabelLarge,
          ),
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false, reservedSize: 16),
      ),
    );
  }

  String _formatMetric(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }
}

class _MetricHeader extends StatelessWidget {
  final VitalsMetricTabData tab;
  final String title;
  final String description;
  final String latestValue;
  final String statusLabel;
  final Color statusColor;
  final String lastRecordedLabel;

  const _MetricHeader({
    required this.tab,
    required this.title,
    required this.description,
    required this.latestValue,
    required this.statusLabel,
    required this.statusColor,
    required this.lastRecordedLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: VitalsStyles.metricIconDecoration(tab.color),
          child: Icon(tab.icon, color: tab.color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: VitalsStyles.metricTitle),
              const SizedBox(height: 2),
              Text(description, style: VitalsStyles.metricDescription),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              latestValue,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: tab.color,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 3,
              ),
              decoration: VitalsStyles.statusBadgeDecoration(statusColor),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(height: 2),
            if (lastRecordedLabel.isNotEmpty)
              Text(lastRecordedLabel, style: VitalsStyles.latestTimestamp),
          ],
        ),
      ],
    );
  }
}

class _NormalRangeLegend extends StatelessWidget {
  final String text;

  const _NormalRangeLegend({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: VitalsStyles.normalRangeLineDecoration,
        ),
        const SizedBox(width: 5),
        Text(text, style: VitalsStyles.normalRangeText),
      ],
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final Color color;

  const _StatData({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _StatsRow extends StatelessWidget {
  final Color color;
  final List<_StatData> cells;

  const _StatsRow({required this.color, required this.cells});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: AppSpacing.sm,
      ),
      decoration: VitalsStyles.statsRowDecoration(color),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            _StatCell(data: cells[i]),
            if (i < cells.length - 1) const _StatDivider(),
          ],
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final _StatData data;

  const _StatCell({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          data.value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: data.color,
          ),
        ),
        const SizedBox(height: 2),
        Text(data.label, style: VitalsStyles.statLabel),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: Colors.grey.shade200);
  }
}

class _AiSummary extends StatelessWidget {
  final String? text;
  final bool loading;
  final String statusLabel;
  final Color statusColor;
  final String title;
  final String generatingLabel;
  final String emptyLabel;

  const _AiSummary({
    required this.text,
    required this.loading,
    required this.statusLabel,
    required this.statusColor,
    required this.title,
    required this.generatingLabel,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: VitalsStyles.aiSummaryDecoration(statusColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon, color: statusColor, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: VitalsStyles.providerBadgeDecoration,
                child: Text(
                  ApiConfig.aiProviderLabel,
                  style: VitalsStyles.providerBadgeText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (loading)
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(generatingLabel, style: VitalsStyles.aiMutedText),
              ],
            )
          else if (text != null && text!.isNotEmpty)
            Text(text!, style: VitalsStyles.aiBody)
          else
            Text(emptyLabel, style: VitalsStyles.aiMutedText),
        ],
      ),
    );
  }

  IconData get _statusIcon {
    if (statusLabel == 'Normal') return Icons.check_circle_outline;
    if (statusLabel == 'No Data') return Icons.help_outline;
    return Icons.warning_amber_outlined;
  }
}

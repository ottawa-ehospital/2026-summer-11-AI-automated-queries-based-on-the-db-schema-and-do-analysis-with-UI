import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../data/models/assistant_models.dart';
import '../../../ui/ui.dart';

class AssistantResultView extends StatelessWidget {
  final AssistantResult result;

  const AssistantResultView({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final item = result;
    if (item is AssistantChartResult) {
      if (item is AssistantUnsupportedChartResult) {
        debugPrint(
          'Unsupported assistant chart displayType: ${item.displayType}',
        );
        return const SizedBox.shrink();
      }
      return AssistantChartResultView(result: item);
    }
    if (item is AssistantReportResult) {
      return AssistantReportResultView(result: item);
    }
    return const SizedBox.shrink();
  }
}

class AssistantReportResultView extends StatelessWidget {
  final AssistantReportResult result;

  const AssistantReportResultView({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final expired = result.isExpired;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: expired ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
        borderRadius: AppRadii.radius(AppRadii.md),
        border: Border.all(
          color: expired ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          if (expired) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'This report may be stale. Your health data or short-term condition may have changed since it was generated.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade900,
              ),
            ),
          ],
          if (result.sourceSummary != null &&
              result.sourceSummary!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                result.sourceSummary!,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          _AssistantMarkdown(content: result.content),
          if (result.freshnessReason.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              result.freshnessReason,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssistantMarkdown extends StatelessWidget {
  final String content;

  const _AssistantMarkdown({required this.content});

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: AppSpacing.xs));
      } else if (trimmed.startsWith('## ')) {
        widgets.add(_markdownText(trimmed.substring(3), 13, FontWeight.w700));
      } else if (trimmed.startsWith('# ')) {
        widgets.add(_markdownText(trimmed.substring(2), 14, FontWeight.w700));
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        widgets.add(_bulletText(trimmed.substring(2)));
      } else {
        widgets.add(_markdownText(trimmed, 12, FontWeight.w400));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _bulletText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 12)),
          Expanded(child: _markdownText(text, 12, FontWeight.w400)),
        ],
      ),
    );
  }

  Widget _markdownText(String text, double size, FontWeight weight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        _stripInlineMarkdown(text),
        style: TextStyle(
          fontSize: size,
          fontWeight: weight,
          color: AppColors.textDark,
          height: 1.35,
        ),
      ),
    );
  }
}

String _stripInlineMarkdown(String value) {
  return value
      .replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (match) => match.group(1) ?? '')
      .replaceAllMapped(RegExp(r'\*([^*]+)\*'), (match) => match.group(1) ?? '')
      .replaceAllMapped(RegExp(r'`([^`]+)`'), (match) => match.group(1) ?? '')
      .replaceAll(RegExp(r'<[^>]+>'), '');
}

class AssistantChartResultView extends StatelessWidget {
  final AssistantChartResult result;

  const AssistantChartResultView({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.series.isEmpty || result.series.first.points.isEmpty) {
      debugPrint('Assistant chart skipped because it has no points.');
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: AppRadii.radius(AppRadii.md),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          if (result.subtitle != null && result.subtitle!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                result.subtitle!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 180,
            child: result.displayType == 'line'
                ? _AssistantLineChart(result: result)
                : _AssistantBarChart(result: result),
          ),
        ],
      ),
    );
  }
}

class _AssistantLineChart extends StatelessWidget {
  final AssistantChartResult result;

  const _AssistantLineChart({required this.result});

  @override
  Widget build(BuildContext context) {
    final points = result.series.first.points;
    final spots = [
      for (var index = 0; index < points.length; index++)
        FlSpot(index.toDouble(), points[index].y),
    ];
    final bounds = _ChartBounds.fromValues(points.map((point) => point.y));

    return LineChart(
      LineChartData(
        minY: bounds.min,
        maxY: bounds.max,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: _titlesData(points, result.yAxis.unit),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2.5,
            color: AppColors.primary,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantBarChart extends StatelessWidget {
  final AssistantChartResult result;

  const _AssistantBarChart({required this.result});

  @override
  Widget build(BuildContext context) {
    final points = result.series.first.points;
    final bounds = _ChartBounds.fromValues(points.map((point) => point.y));

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: bounds.max,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: _titlesData(points, result.yAxis.unit),
        barGroups: [
          for (var index = 0; index < points.length; index++)
            BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: points[index].y,
                  width: 8,
                  borderRadius: BorderRadius.circular(3),
                  color: AppColors.primary,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

FlTitlesData _titlesData(List<AssistantChartPoint> points, String? unit) {
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 42,
        maxIncluded: false,
        minIncluded: false,
        getTitlesWidget: (value, _) {
          final suffix = unit == null || unit.isEmpty ? '' : ' $unit';
          return Text(
            '${value.round()}$suffix',
            style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
          );
        },
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 28,
        interval: _bottomInterval(points.length),
        getTitlesWidget: (value, _) {
          final index = value.round();
          if (index < 0 || index >= points.length)
            return const SizedBox.shrink();
          final label = points[index].label ?? points[index].x.toString();
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _compactLabel(label),
              style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
            ),
          );
        },
      ),
    ),
  );
}

double _bottomInterval(int count) {
  if (count <= 4) return 1;
  return (count / 4).ceilToDouble();
}

String _compactLabel(String value) {
  if (value.length <= 8) return value;
  if (value.contains('T')) return value.split('T').first;
  return value.substring(0, 8);
}

class _ChartBounds {
  final double min;
  final double max;

  const _ChartBounds({required this.min, required this.max});

  factory _ChartBounds.fromValues(Iterable<double> values) {
    final list = values.toList();
    final min = list.reduce((a, b) => a < b ? a : b);
    final max = list.reduce((a, b) => a > b ? a : b);
    if (min == max) {
      return _ChartBounds(min: min - 1, max: max + 1);
    }
    final padding = (max - min) * 0.12;
    return _ChartBounds(min: min - padding, max: max + padding);
  }
}

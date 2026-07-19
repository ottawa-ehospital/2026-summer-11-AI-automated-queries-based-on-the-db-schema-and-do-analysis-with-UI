import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../config/api_config.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../presentation/trend_styles.dart';

class TrendMetricCard extends StatelessWidget {
  final AppLocalizations l10n;
  final IconData icon;
  final String title;
  final String description;
  final double thisWeek;
  final double lastWeek;
  final String unit;
  final Color color;
  final double normalMin;
  final double normalMax;
  final String? aiText;
  final bool aiGenerating;

  const TrendMetricCard({
    super.key,
    required this.l10n,
    required this.icon,
    required this.title,
    required this.description,
    required this.thisWeek,
    required this.lastWeek,
    required this.unit,
    required this.color,
    required this.normalMin,
    required this.normalMax,
    required this.aiText,
    required this.aiGenerating,
  });

  @override
  Widget build(BuildContext context) {
    final percent = _percentLabel();
    final percentColor = _percentColor();
    final status = _status();
    final maxValue = [thisWeek, lastWeek, normalMax * 0.5, 1.0].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: TrendStyles.metricCardPadding,
      decoration: TrendStyles.metricCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricHeader(
            icon: icon,
            title: title,
            description: description,
            color: color,
            percent: percent,
            percentColor: percentColor,
            percentIcon: _percentIcon(),
            status: status.label,
            statusColor: status.color,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.35,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => _bottomTitle(value),
                      reservedSize: 36,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _barGroup(0, lastWeek > 0 ? lastWeek : 0.001, color.withValues(alpha: 0.4)),
                  _barGroup(1, thisWeek > 0 ? thisWeek : 0.001, color),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _AiInsightPanel(
            l10n: l10n,
            color: status.color,
            thisWeek: thisWeek,
            lastWeek: lastWeek,
            aiText: aiText,
            aiGenerating: aiGenerating,
          ),
        ],
      ),
    );
  }

  Widget _bottomTitle(double value) {
    final index = value.toInt();
    final labels = [
      l10n.trendChartAxisLabel(l10n.lastWeekLabel, _format(lastWeek), unit),
      l10n.trendChartAxisLabel(l10n.thisWeekLabel, _format(thisWeek), unit),
    ];
    if (index < 0 || index >= labels.length) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        labels[index],
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          color: index == 1 ? color : AppColors.textMuted,
          fontWeight: index == 1 ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double value, Color barColor) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: barColor,
          width: 44,
          borderRadius: AppRadii.radius(AppSpacing.sm),
        ),
      ],
    );
  }

  String _percentLabel() {
    if (lastWeek == 0) return thisWeek > 0 ? '+inf' : '-';
    final percent = ((thisWeek - lastWeek) / lastWeek * 100);
    return '${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(1)}%';
  }

  Color _percentColor() {
    if (lastWeek == 0) return AppColors.textMuted;
    return thisWeek >= lastWeek ? Colors.green : Colors.red;
  }

  IconData _percentIcon() {
    if (lastWeek == 0) return Icons.remove;
    return thisWeek >= lastWeek ? Icons.arrow_upward : Icons.arrow_downward;
  }

  ({String label, Color color}) _status() {
    if (thisWeek <= 0) return (label: l10n.noDataThisWeek, color: Colors.grey);
    if (thisWeek < normalMin) return (label: l10n.belowNormalRange, color: Colors.orange);
    if (thisWeek > normalMax) return (label: l10n.aboveNormalRange, color: Colors.red);
    return (label: l10n.withinNormalRange, color: Colors.green);
  }

  String _format(double value) => value == value.roundToDouble() ? value.round().toString() : value.toStringAsFixed(1);
}

class _MetricHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String percent;
  final Color percentColor;
  final IconData percentIcon;
  final String status;
  final Color statusColor;

  const _MetricHeader({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.percent,
    required this.percentColor,
    required this.percentIcon,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: TrendStyles.metricIconDecoration(color),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TrendStyles.metricTitle),
              Text(description, style: TrendStyles.metricDescription),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Icon(percentIcon, size: 14, color: percentColor),
                const SizedBox(width: 3),
                Text(percent, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: percentColor)),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: TrendStyles.statusChipDecoration(statusColor),
              child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor)),
            ),
          ],
        ),
      ],
    );
  }
}

class _AiInsightPanel extends StatelessWidget {
  final AppLocalizations l10n;
  final Color color;
  final double thisWeek;
  final double lastWeek;
  final String? aiText;
  final bool aiGenerating;

  const _AiInsightPanel({
    required this.l10n,
    required this.color,
    required this.thisWeek,
    required this.lastWeek,
    required this.aiText,
    required this.aiGenerating,
  });

  @override
  Widget build(BuildContext context) {
    final loading = aiGenerating && aiText == null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: TrendStyles.insightDecoration(color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon(), size: 14, color: color),
              const SizedBox(width: 6),
              Text(l10n.aiInsightLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: TrendStyles.providerBadgeDecoration,
                child: Text(
                  ApiConfig.aiProviderLabel,
                  style: const TextStyle(fontSize: 8, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (loading)
            Row(
              children: [
                const SizedBox(
                  width: AppSpacing.md,
                  height: AppSpacing.md,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(l10n.generatingInsight, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            )
          else if (aiText != null && aiText!.isNotEmpty)
            Text(aiText!, style: TrendStyles.insightBody)
          else
            Text(l10n.syncDataToGenerateInsight, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  IconData _icon() {
    if (thisWeek <= 0) return Icons.help_outline;
    return thisWeek >= lastWeek ? Icons.trending_up : Icons.trending_down;
  }
}

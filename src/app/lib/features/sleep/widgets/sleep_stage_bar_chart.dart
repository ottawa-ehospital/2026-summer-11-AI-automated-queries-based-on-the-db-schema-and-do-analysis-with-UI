import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/night_sleep.dart';

class SleepStageBarChart extends StatelessWidget {
  final List<NightSleep> nights;
  const SleepStageBarChart({super.key, required this.nights});

  // Stage palette (kept in sync with the legend)
  static const deepColor = Color(0xFF3F51B5); // indigo
  static const remColor = Color(0xFF8E24AA); // purple
  static const coreColor = Color(0xFF42A5F5); // blue
  static const awakeColor = Color(0xFFEF5350); // red

  @override
  Widget build(BuildContext context) {
    if (nights.isEmpty) {
      return const SizedBox(height: 220, child: Center(child: Text('No data')));
    }

    double maxTotal = 0;
    for (final n in nights) {
      final total =
          n.deepMinutes + n.remMinutes + n.coreMinutes + n.awakeMinutes;
      if (total > maxTotal) maxTotal = total;
    }
    // Round the top up to the next whole hour, with a little headroom.
    final maxY = (((maxTotal / 60).ceil()) + 1) * 60.0;

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBorderRadius: BorderRadius.circular(8),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              getTooltipColor: (_) => const Color(0xFF2A2A3C),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final n = nights[group.x.toInt()];
                final total =
                    n.deepMinutes +
                    n.remMinutes +
                    n.coreMinutes +
                    n.awakeMinutes;
                String h(double m) => '${(m / 60).toStringAsFixed(1)}h';
                return BarTooltipItem(
                  '${n.night.substring(5)}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: 'Total ${h(total)}\n',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    TextSpan(
                      text:
                          'Deep ${h(n.deepMinutes)}  REM ${h(n.remMinutes)}\n'
                          'Core ${h(n.coreMinutes)}  Awake ${h(n.awakeMinutes)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 120,
            getDrawingHorizontalLine: (v) => FlLine(
              color: Colors.grey.withValues(alpha: 0.15),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 120,
                getTitlesWidget: (value, meta) => Text(
                  '${(value / 60).toStringAsFixed(0)}h',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= nights.length) return const SizedBox();
                  final label = nights[i].night.length >= 10
                      ? nights[i].night.substring(5) // MM-DD
                      : nights[i].night;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(nights.length, (i) {
            final n = nights[i];
            final deepEnd = n.deepMinutes;
            final remEnd = deepEnd + n.remMinutes;
            final coreEnd = remEnd + n.coreMinutes;
            final awakeEnd = coreEnd + n.awakeMinutes;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: awakeEnd,
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: Colors.grey.withValues(alpha: 0.06),
                  ),
                  rodStackItems: [
                    BarChartRodStackItem(0, deepEnd, deepColor),
                    BarChartRodStackItem(deepEnd, remEnd, remColor),
                    BarChartRodStackItem(remEnd, coreEnd, coreColor),
                    BarChartRodStackItem(coreEnd, awakeEnd, awakeColor),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

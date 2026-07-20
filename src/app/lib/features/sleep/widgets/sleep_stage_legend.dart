import 'package:flutter/material.dart';
import 'sleep_stage_bar_chart.dart';

class SleepStageLegend extends StatelessWidget {
  const SleepStageLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        _item('Deep', SleepStageBarChart.deepColor),
        _item('REM', SleepStageBarChart.remColor),
        _item('Core', SleepStageBarChart.coreColor),
        _item('Awake', SleepStageBarChart.awakeColor),
      ],
    );
  }

  Widget _item(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

class SimulationDayChip extends StatelessWidget {
  final int day;
  final bool uploaded;
  final bool current;

  const SimulationDayChip({
    super.key,
    required this.day,
    required this.uploaded,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors();

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: uploaded
            ? Icon(Icons.check, size: 14, color: fg)
            : current
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                : Text(
                    'D$day',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fg),
                  ),
      ),
    );
  }

  (Color, Color) _colors() {
    if (uploaded) return (Colors.green.withValues(alpha: 0.15), Colors.green);
    if (current) return (AppColors.primarySoft, AppColors.primary);
    return (Colors.grey.shade100, Colors.grey.shade400);
  }
}

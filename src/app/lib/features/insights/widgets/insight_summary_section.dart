import 'package:flutter/material.dart';

class InsightSummarySection extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const InsightSummarySection({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
